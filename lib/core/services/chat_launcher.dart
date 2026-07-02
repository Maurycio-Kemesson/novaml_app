import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Estado do processo do serviço de chat.
enum ChatState { stopped, starting, running, error }

/// Gerencia o ciclo de vida completo do assistente IA:
///
///   1. Verifica se o Ollama já está rodando (porta 11434).
///   2. Se não estiver, inicia `ollama serve` automaticamente.
///   3. Aguarda o Ollama ficar pronto.
///   4. Inicia o servidor novaml-chat (FastAPI + RAG) na porta 8001.
///
/// Pré-requisitos únicos (feitos uma vez pelo desenvolvedor):
///   - Ollama instalado: https://ollama.com/download
///   - Modelo baixado: `ollama pull qwen2.5:7b`
///   - PDFs indexados: `cd novaml-chat && venv\Scripts\python rag/ingest.py`
///   - Dependências: `cd novaml-chat && python -m venv venv && venv\Scripts\pip install ...`
class ChatLauncher {
  ChatLauncher._();
  static final ChatLauncher instance = ChatLauncher._();

  static const int port       = 8001;   // novaml-chat FastAPI
  static const int ollamaPort = 11434;  // Ollama padrão

  Process? _chatProcess;
  Process? _ollamaProcess;   // só preenchido se nós iniciamos o Ollama
  ChatState _state = ChatState.stopped;

  final List<String> _logs = [];
  final _logController = StreamController<String>.broadcast();

  ChatState get state => _state;
  List<String> get logs => List.unmodifiable(_logs);

  /// Stream de logs em tempo real.
  Stream<String> get logStream => _logController.stream;

  // ─────────────────────────────────────────────────────────────────────────
  // Público
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_state == ChatState.running || _state == ChatState.starting) return;
    _state = ChatState.starting;
    _log('Iniciando serviço de chat NOVAML...');

    // ── 1. Localizar o diretório novaml-chat ───────────────────────────────
    final chatDir = await _findChatDir();
    if (chatDir == null) {
      _state = ChatState.error;
      _log('ERRO: Diretório novaml-chat não encontrado.');
      _log('Certifique-se de que a pasta novaml-chat/ existe junto ao projeto.');
      return;
    }

    // ── 2. Localizar Python do venv ────────────────────────────────────────
    final python = await _findPython(chatDir);
    if (python == null) {
      _state = ChatState.error;
      _log('ERRO: Python/venv não encontrado em $chatDir');
      _log('Execute no PowerShell:');
      _log('  cd novaml-chat');
      _log('  python -m venv venv');
      _log('  venv\\Scripts\\pip install fastapi uvicorn langchain langchain-community langchain-chroma langchain-ollama chromadb pypdf ollama pandas python-multipart');
      return;
    }

    // ── 3. Verificar ChromaDB (ingest.py já rodou?) ────────────────────────
    final chromaDir = Directory(p.join(chatDir, 'chroma_db'));
    if (!chromaDir.existsSync()) {
      _state = ChatState.error;
      _log('ERRO: ChromaDB não encontrado. Os PDFs precisam ser indexados primeiro.');
      _log('Execute uma vez no PowerShell:');
      _log('  cd novaml-chat');
      _log('  venv\\Scripts\\python rag/ingest.py');
      return;
    }

    // ── 4. Garantir que o Ollama está rodando ──────────────────────────────
    final ollamaOk = await _ensureOllama();
    if (!ollamaOk) {
      _state = ChatState.error;
      _log('ERRO: Não foi possível iniciar o Ollama.');
      _log('Verifique se o Ollama está instalado: https://ollama.com/download');
      _log('E se o modelo está baixado: ollama pull qwen2.5:7b');
      return;
    }

    // ── 5. Iniciar o servidor novaml-chat ──────────────────────────────────
    _log('Iniciando servidor novaml-chat...');
    _log('Diretório: $chatDir');
    _log('Python: $python');

    try {
      final env = Map<String, String>.from(Platform.environment)
        ..['CHAT_PORT']   = '$port'
        ..['CHAT_HOST']   = '127.0.0.1'
        ..['CHROMA_PATH'] = p.join(chatDir, 'chroma_db');

      _chatProcess = await Process.start(
        python,
        ['main.py'],
        workingDirectory: chatDir,
        environment: env,
      );

      _chatProcess!.stdout
          .transform(const SystemEncoding().decoder)
          .listen(_log);
      _chatProcess!.stderr
          .transform(const SystemEncoding().decoder)
          .listen((line) => _log('[ERR] $line'));

      _chatProcess!.exitCode.then((code) {
        _log('Processo de chat encerrado com código $code');
        if (code != 0) _log('ERRO: Serviço de chat encerrou inesperadamente.');
        _state = code == 0 ? ChatState.stopped : ChatState.error;
        _chatProcess = null;
      });

      _log('Aguardando serviço de chat ficar pronto...');
      final ready = await _waitPort(port, timeout: const Duration(seconds: 60));

      if (ready) {
        _state = ChatState.running;
        _log('✓ Serviço de chat pronto em http://localhost:$port');
      } else {
        _state = ChatState.error;
        _log('ERRO: Serviço de chat não respondeu no tempo limite (60s).');
      }
    } catch (e) {
      _state = ChatState.error;
      _log('ERRO ao iniciar processo: $e');
    }
  }

  Future<void> stop() async {
    _chatProcess?.kill();
    _chatProcess = null;
    // Só mata o Ollama se nós o iniciamos
    _ollamaProcess?.kill();
    _ollamaProcess = null;
    _state = ChatState.stopped;
    _log('Serviço de chat encerrado.');
  }

  Future<void> restart() async {
    _log('Reiniciando serviço de chat...');
    await stop();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await start();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Ollama
  // ─────────────────────────────────────────────────────────────────────────

  /// Garante que o Ollama está respondendo na porta 11434.
  /// Se não estiver, tenta iniciar `ollama serve`.
  /// Retorna true se o Ollama ficar pronto dentro do timeout.
  Future<bool> _ensureOllama() async {
    // Verifica se já está rodando
    if (await _isPortOpen(ollamaPort)) {
      _log('✓ Ollama já está rodando na porta $ollamaPort.');
      return true;
    }

    _log('Ollama não detectado — tentando iniciar automaticamente...');

    // Localiza o executável do Ollama
    final ollamaExe = await _findOllamaExe();
    if (ollamaExe == null) {
      _log('AVISO: ollama não encontrado no PATH.');
      _log('Instale em: https://ollama.com/download');
      return false;
    }

    _log('Iniciando: $ollamaExe serve');

    try {
      _ollamaProcess = await Process.start(
        ollamaExe,
        ['serve'],
        mode: ProcessStartMode.detachedWithStdio,
      );

      _ollamaProcess!.stdout
          .transform(const SystemEncoding().decoder)
          .listen((l) => _log('[Ollama] $l'));
      _ollamaProcess!.stderr
          .transform(const SystemEncoding().decoder)
          .listen((l) => _log('[Ollama] $l'));

      _log('Aguardando Ollama ficar pronto (até 30s)...');
      final ready = await _waitPort(ollamaPort, timeout: const Duration(seconds: 30));

      if (ready) {
        _log('✓ Ollama pronto na porta $ollamaPort.');
        return true;
      } else {
        _log('ERRO: Ollama não respondeu no tempo limite.');
        return false;
      }
    } catch (e) {
      _log('ERRO ao iniciar Ollama: $e');
      return false;
    }
  }

  /// Procura o executável `ollama` no PATH e em locais comuns do Windows.
  Future<String?> _findOllamaExe() async {
    // Tenta via PATH primeiro
    for (final exe in ['ollama', 'ollama.exe']) {
      try {
        final r = await Process.run(exe, ['--version']);
        if (r.exitCode == 0) return exe;
      } catch (_) {}
    }

    // Locais padrão de instalação no Windows
    if (Platform.isWindows) {
      final candidates = [
        r'C:\Users\' +
            (Platform.environment['USERNAME'] ?? '') +
            r'\AppData\Local\Programs\Ollama\ollama.exe',
        r'C:\Program Files\Ollama\ollama.exe',
        r'C:\Program Files (x86)\Ollama\ollama.exe',
      ];
      for (final path in candidates) {
        if (File(path).existsSync()) return path;
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resolução de diretório
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> _findChatDir() async {
    final envPath = Platform.environment['NOVAML_CHAT_PATH'];
    if (envPath != null && File(p.join(envPath, 'main.py')).existsSync()) {
      return p.normalize(envPath);
    }

    final bases = [
      p.dirname(Platform.executable),
      Directory.current.path,
    ];

    const suffixes = [
      'novaml-chat',
      '../novaml-chat',
      '../../novaml-chat',
      '../../../novaml-chat',
      '../../../../novaml-chat',
    ];

    for (final base in bases) {
      for (final suffix in suffixes) {
        final candidate = p.normalize(p.join(base, suffix));
        if (File(p.join(candidate, 'main.py')).existsSync() &&
            Directory(p.join(candidate, 'rag')).existsSync()) {
          return candidate;
        }
      }
    }
    return null;
  }

  /// Prioridade: venv → .venv → env → Python global.
  Future<String?> _findPython(String chatDir) async {
    final venvCandidates = Platform.isWindows
        ? [
            p.join(chatDir, 'venv', 'Scripts', 'python.exe'),
            p.join(chatDir, '.venv', 'Scripts', 'python.exe'),
            p.join(chatDir, 'env', 'Scripts', 'python.exe'),
          ]
        : [
            p.join(chatDir, 'venv', 'bin', 'python'),
            p.join(chatDir, '.venv', 'bin', 'python'),
            p.join(chatDir, 'env', 'bin', 'python'),
          ];

    for (final exe in venvCandidates) {
      if (File(exe).existsSync()) {
        _log('Venv encontrado: $exe');
        return exe;
      }
    }

    _log('Nenhum venv encontrado — tentando Python global...');
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
  // Utilitários de rede
  // ─────────────────────────────────────────────────────────────────────────

  /// Retorna true se conseguir conectar TCP na porta especificada.
  Future<bool> _isPortOpen(int targetPort) async {
    try {
      final socket = await Socket.connect(
        'localhost',
        targetPort,
        timeout: const Duration(milliseconds: 500),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fica tentando conectar até [timeout] ou a porta abrir.
  Future<bool> _waitPort(int targetPort, {required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _isPortOpen(targetPort)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 1000));
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logs
  // ─────────────────────────────────────────────────────────────────────────

  void _log(String msg) {
    final entry = '[CHAT ${_ts()}] $msg';
    _logs.add(entry);
    if (_logs.length > 400) _logs.removeAt(0);
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
