import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Estado do processo backend.
enum BackendState { stopped, starting, running, error }

/// Modo de execução do backend.
enum BackendMode {
  /// Executável compilado (PyInstaller) — modo produção/instalador.
  compiled,

  /// python main.py em venv/dev — modo desenvolvimento.
  development,
}

/// Gerencia o ciclo de vida do processo Python (FastAPI NOVAML).
///
/// ## Modo Produção (instalador)
/// Procura por `novaml_api.exe` (ou `novaml-api.exe`) no mesmo diretório
/// do executável Flutter. Gerado com PyInstaller — sem Python instalado.
///
/// ## Modo Desenvolvimento
/// Procura pelo diretório `novaml-api/` com `main.py` e usa o Python do
/// venv (.venv/Scripts/python.exe) ou o Python global como fallback.
///
/// A detecção é automática — produção tem prioridade.
class BackendLauncher {
  BackendLauncher._();
  static final BackendLauncher instance = BackendLauncher._();

  Process? _process;
  BackendState _state = BackendState.stopped;
  BackendMode? _mode;

  final List<String> _logs = [];
  final _logController = StreamController<String>.broadcast();

  BackendState get state => _state;
  BackendMode? get mode => _mode;
  List<String> get logs => List.unmodifiable(_logs);

  /// Stream de logs em tempo real — assine no Riverpod / UI.
  Stream<String> get logStream => _logController.stream;

  // ─────────────────────────────────────────────────────────────────────────
  // Público
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_state == BackendState.running || _state == BackendState.starting) {
      return;
    }
    _state = BackendState.starting;
    _log('Iniciando backend NOVAML...');

    // ── Verificar se já há algo na porta 8000 ──────────────────────────────
    if (await _isPortOpen(8000)) {
      _log('Porta 8000 já está em uso — verificando se é o novaml-api...');
      final alreadyUp = await _waitReady(timeout: const Duration(seconds: 3));
      if (alreadyUp) {
        _state = BackendState.running;
        _log('✓ Backend já está rodando em http://localhost:8000 (reaproveitado).');
        return;
      } else {
        _state = BackendState.error;
        _log('ERRO: Porta 8000 ocupada por outro processo.');
        _log('Libere a porta e reinicie o app:');
        _log('  netstat -ano | findstr :8000   → anote o PID');
        _log('  taskkill /PID <numero> /F');
        return;
      }
    }

    final cmd = await _resolveCommand();
    if (cmd == null) {
      _state = BackendState.error;
      _log('ERRO: Não foi possível localizar o backend.');
      _log('');
      _log('► Modo produção: certifique-se de que novaml_api.exe está na '
          'mesma pasta do aplicativo.');
      _log('► Modo dev: crie um venv em novaml-api/.venv e instale '
          'os requirements.');
      return;
    }

    _log('Modo: ${_mode == BackendMode.compiled ? "produção (exe)" : "desenvolvimento (python)"}');
    _log('Comando: ${cmd.exe} ${cmd.args.join(' ')}');

    try {
      final env = Map<String, String>.from(Platform.environment)
        ..['CONFIG_PATH'] = cmd.configPath;

      _process = await Process.start(
        cmd.exe,
        cmd.args,
        workingDirectory: cmd.workDir,
        environment: env,
      );

      _process!.stdout
          .transform(const SystemEncoding().decoder)
          .listen(_log);
      _process!.stderr
          .transform(const SystemEncoding().decoder)
          .listen((line) => _log('[ERR] $line'));

      _process!.exitCode.then((code) {
        _log('Processo encerrado com código $code');
        if (code != 0) {
          _log('ERRO: Backend encerrou inesperadamente — veja os logs acima.');
        }
        _state = code == 0 ? BackendState.stopped : BackendState.error;
        _process = null;
      });

      // scikit-learn + numpy demoram ~5-10s para importar; .exe compila mais rápido.
      final timeout = _mode == BackendMode.compiled
          ? const Duration(seconds: 20)
          : const Duration(seconds: 40);

      _log('Aguardando servidor ficar pronto...');
      final ready = await _waitReady(timeout: timeout);

      if (ready) {
        _state = BackendState.running;
        _log('✓ Backend pronto em http://localhost:8000');
      } else {
        _state = BackendState.error;
        _log('ERRO: Backend não respondeu no tempo limite.');
        if (_mode == BackendMode.development) {
          _log('Dica: verifique se todos os pacotes do requirements.txt '
              'estão instalados no venv.');
        }
      }
    } catch (e) {
      _state = BackendState.error;
      _log('ERRO ao iniciar processo: $e');
    }
  }

  Future<void> stop() async {
    _process?.kill();
    _process = null;
    _state = BackendState.stopped;
    _log('Backend encerrado.');
  }

  Future<void> restart() async {
    _log('Reiniciando backend...');
    await stop();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await start();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resolução de comando
  // ─────────────────────────────────────────────────────────────────────────

  /// Retorna o comando resolvido (exe + args + workDir + configPath)
  /// ou null se nenhum modo for viável.
  Future<_BackendCommand?> _resolveCommand() async {
    // ── 1. Modo produção — .exe compilado pelo PyInstaller ─────────────────
    final compiled = await _findCompiledExe();
    if (compiled != null) {
      _mode = BackendMode.compiled;
      return compiled;
    }

    // ── 2. Modo desenvolvimento — python main.py ───────────────────────────
    final apiDir = await _findApiDir();
    if (apiDir != null) {
      final python = await _findPython(apiDir);
      if (python != null) {
        _mode = BackendMode.development;
        return _BackendCommand(
          exe: python,
          args: ['main.py'],
          workDir: apiDir,
          configPath: apiDir,
        );
      }
      _log('AVISO: Diretório novaml-api encontrado mas Python não localizado.');
    }

    return null;
  }

  /// Procura pelo executável compilado produzido pelo PyInstaller.
  ///
  /// Estrutura esperada no instalador:
  /// ```
  /// install_dir/
  ///   novaml_app.exe         ← Flutter
  ///   novaml_api.exe         ← PyInstaller (--onefile)
  ///   data/                  ← CONFIG_PATH (modelos exportados, DB)
  /// ```
  Future<_BackendCommand?> _findCompiledExe() async {
    final exeDir = p.dirname(Platform.executable);

    // Nomes possíveis do executável compilado
    const names = ['novaml_api.exe', 'novaml-api.exe', 'backend.exe'];

    // Subpastas onde o exe pode estar
    const subDirs = ['', 'backend', 'api'];

    for (final sub in subDirs) {
      for (final name in names) {
        final candidate = p.normalize(
          sub.isEmpty ? p.join(exeDir, name) : p.join(exeDir, sub, name),
        );
        if (File(candidate).existsSync()) {
          _log('Executável compilado encontrado: $candidate');

          // CONFIG_PATH = data/ junto ao exe (criado pelo instalador ou
          // automaticamente pelo app no primeiro uso)
          final dataDir = p.join(exeDir, 'data');
          Directory(dataDir).createSync(recursive: true);

          return _BackendCommand(
            exe: candidate,
            args: [],
            workDir: exeDir,
            configPath: dataDir,
          );
        }
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers — modo desenvolvimento
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> _findApiDir() async {
    final envPath = Platform.environment['NOVAML_API_PATH'];
    if (envPath != null && File(p.join(envPath, 'main.py')).existsSync()) {
      return p.normalize(envPath);
    }

    final bases = [
      p.dirname(Platform.executable),
      Directory.current.path,
    ];

    const suffixes = [
      'novaml-api',
      '../novaml-api',
      '../../novaml-api',
      '../../../novaml-api',
      '../../../../novaml-api',
    ];

    for (final base in bases) {
      for (final suffix in suffixes) {
        final candidate = p.normalize(p.join(base, suffix));
        if (File(p.join(candidate, 'main.py')).existsSync()) {
          return candidate;
        }
      }
    }
    return null;
  }

  /// Prioridade: venv do projeto → Python global.
  Future<String?> _findPython(String apiDir) async {
    final venvCandidates = Platform.isWindows
        ? [
            p.join(apiDir, '.venv', 'Scripts', 'python.exe'),
            p.join(apiDir, 'venv', 'Scripts', 'python.exe'),
            p.join(apiDir, 'env', 'Scripts', 'python.exe'),
          ]
        : [
            p.join(apiDir, '.venv', 'bin', 'python'),
            p.join(apiDir, 'venv', 'bin', 'python'),
            p.join(apiDir, 'env', 'bin', 'python'),
          ];

    for (final exe in venvCandidates) {
      if (File(exe).existsSync()) {
        _log('Venv encontrado: $exe');
        return exe;
      }
    }

    _log('Nenhum venv — tentando Python global...');
    for (final exe in ['python', 'python3', 'py']) {
      try {
        final r = await Process.run(exe, ['--version']);
        if (r.exitCode == 0) {
          _log('Python global: $exe (${(r.stdout as String).trim()})');
          return exe;
        }
      } catch (_) {}
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilitários
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _isPortOpen(int port) async {
    try {
      final socket = await Socket.connect(
        'localhost',
        port,
        timeout: const Duration(milliseconds: 500),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _waitReady({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _isPortOpen(8000)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    return false;
  }

  void _log(String msg) {
    final entry = '[${_ts()}] $msg';
    _logs.add(entry);
    if (_logs.length > 500) _logs.removeAt(0);
    _logController.add(entry);
    // ignore: avoid_print
    print(entry);
  }

  String _ts() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BackendCommand {
  const _BackendCommand({
    required this.exe,
    required this.args,
    required this.workDir,
    required this.configPath,
  });

  final String exe;
  final List<String> args;
  final String workDir;
  final String configPath;
}
