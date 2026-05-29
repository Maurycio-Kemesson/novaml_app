import 'dart:convert';
import 'dart:io';

/// Dados de recursos do sistema coletados do Windows.
class SystemInfo {
  final double ramUsedGb;
  final double ramTotalGb;
  final double diskUsedGb;
  final double diskTotalGb;
  final int gpuPercent;
  final bool gpuAvailable;

  const SystemInfo({
    required this.ramUsedGb,
    required this.ramTotalGb,
    required this.diskUsedGb,
    required this.diskTotalGb,
    required this.gpuPercent,
    required this.gpuAvailable,
  });

  /// Valor de carregamento/placeholder antes do primeiro fetch.
  factory SystemInfo.loading() => const SystemInfo(
        ramUsedGb: 0,
        ramTotalGb: 1,
        diskUsedGb: 0,
        diskTotalGb: 1,
        gpuPercent: 0,
        gpuAvailable: false,
      );

  String get ramLabel =>
      '${ramUsedGb.toStringAsFixed(1)}GB / ${ramTotalGb.toStringAsFixed(0)}GB';

  String get diskLabel {
    if (diskTotalGb >= 1024) {
      final usedTb = diskUsedGb / 1024;
      final totalTb = diskTotalGb / 1024;
      return '${usedTb.toStringAsFixed(1)}TB / ${totalTb.toStringAsFixed(1)}TB';
    }
    return '${diskUsedGb.toStringAsFixed(0)}GB / ${diskTotalGb.toStringAsFixed(0)}GB';
  }

  String get gpuLabel =>
      gpuAvailable ? 'GPU: ${gpuPercent}%' : 'GPU: IDLE (${gpuPercent}%)';

  double get ramFraction => (ramUsedGb / ramTotalGb).clamp(0.0, 1.0);
  double get diskFraction => (diskUsedGb / diskTotalGb).clamp(0.0, 1.0);
}

/// Serviço que coleta dados reais de recursos do Windows 11
/// via um único processo PowerShell por chamada.
abstract final class SystemInfoService {
  /// Script PowerShell que retorna JSON com RAM, Disco C: e GPU.
  /// Executado em uma única chamada para minimizar overhead.
  static const String _script = r'''
try {
  $os   = Get-WmiObject Win32_OperatingSystem
  $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
  $gpu  = 0
  $gpuOk = $false
  try {
    $raw = & nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>$null
    if ($LASTEXITCODE -eq 0) {
      $gpu = [int]($raw -replace '\s','')
      $gpuOk = $true
    }
  } catch {}
  [PSCustomObject]@{
    RamTotalKb = [long]$os.TotalVisibleMemorySize
    RamFreeKb  = [long]$os.FreePhysicalMemory
    DiskSizeB  = [long]$disk.Size
    DiskFreeB  = [long]$disk.FreeSpace
    GpuPercent = $gpu
    GpuOk      = $gpuOk
  } | ConvertTo-Json -Compress
} catch {
  '{"error": true}'
}
''';

  /// Executa um fetch e retorna um [SystemInfo].
  /// Nunca lança exceção — retorna [SystemInfo.loading()] em caso de falha.
  static Future<SystemInfo> fetch() async {
    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', _script],
        stdoutEncoding: const Utf8Codec(allowMalformed: true),
        stderrEncoding: const Utf8Codec(allowMalformed: true),
      );

      if (result.exitCode != 0) return SystemInfo.loading();

      final raw = (result.stdout as String).trim();
      if (raw.isEmpty || raw.startsWith('{"error"')) {
        return SystemInfo.loading();
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;

      final ramTotalKb = (json['RamTotalKb'] as num).toDouble();
      final ramFreeKb  = (json['RamFreeKb']  as num).toDouble();
      final diskSizeB  = (json['DiskSizeB']  as num).toDouble();
      final diskFreeB  = (json['DiskFreeB']  as num).toDouble();
      final gpuPercent = (json['GpuPercent'] as num).toInt();
      final gpuOk      = json['GpuOk'] as bool? ?? false;

      final ramTotalGb = ramTotalKb / (1024 * 1024);
      final ramUsedGb  = (ramTotalKb - ramFreeKb) / (1024 * 1024);
      final diskTotalGb = diskSizeB  / (1024 * 1024 * 1024);
      final diskUsedGb  = (diskSizeB - diskFreeB) / (1024 * 1024 * 1024);

      return SystemInfo(
        ramUsedGb:    ramUsedGb,
        ramTotalGb:   ramTotalGb,
        diskUsedGb:   diskUsedGb,
        diskTotalGb:  diskTotalGb,
        gpuPercent:   gpuPercent,
        gpuAvailable: gpuOk,
      );
    } catch (_) {
      return SystemInfo.loading();
    }
  }
}
