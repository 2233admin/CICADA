import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../app/widgets/scan_line_overlay.dart';
import '../services/installer_service.dart';
import '../services/config_service.dart';
import '../widgets/terminal_output.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<bool>? onServiceStatusChanged;

  const DashboardPage({super.key, this.onServiceStatusChanged});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  String _nodeVersion = '检测中...';
  String _openclawVersion = '检测中...';
  bool _serviceRunning = false;
  bool _actionLoading = false;
  Set<String> _configuredProviders = {};
  Timer? _pollTimer;
  Timer? _clockTimer;
  final List<String> _serviceLog = [];

  // Uptime tracking
  DateTime? _serviceStartTime;
  Duration _uptime = Duration.zero;

  // Clock
  String _clockString = '';

  // Blinking cursor animation
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _cursorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_cursorController);

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      if (_serviceRunning && _serviceStartTime != null) {
        setState(() => _uptime = DateTime.now().difference(_serviceStartTime!));
      }
    });

    _detectEnvironment();
    _loadConfiguredProviders();
    _checkServiceStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkServiceStatus());
  }

  void _updateClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    setState(() => _clockString = '$h:$m:$s');
  }

  String get _uptimeString {
    if (!_serviceRunning) return '--:--:--';
    final h = _uptime.inHours.toString().padLeft(2, '0');
    final m = (_uptime.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_uptime.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  Future<void> _detectEnvironment() async {
    final nodeResult = await InstallerService.checkNode();
    final clawResult = await InstallerService.checkOpenClaw();
    if (!mounted) return;
    setState(() {
      _nodeVersion = nodeResult.exitCode == 0
          ? nodeResult.stdout.toString().trim()
          : '未安装';
      _openclawVersion = clawResult.exitCode == 0
          ? clawResult.stdout.toString().trim()
          : '未安装';
    });
  }

  Future<void> _loadConfiguredProviders() async {
    final configured = await ConfigService.getConfiguredProviders();
    if (!mounted) return;
    setState(() => _configuredProviders = configured);
  }

  Future<void> _checkServiceStatus() async {
    final running = await InstallerService.isServiceRunning();
    if (!mounted) return;
    if (running != _serviceRunning) {
      setState(() {
        _serviceRunning = running;
        if (running) {
          _serviceStartTime = DateTime.now();
          _uptime = Duration.zero;
        } else {
          _serviceStartTime = null;
          _uptime = Duration.zero;
        }
      });
      widget.onServiceStatusChanged?.call(running);
    }
  }

  Future<void> _toggleService() async {
    setState(() {
      _actionLoading = true;
      _serviceLog.clear();
    });
    try {
      ProcessResult result;
      if (_serviceRunning) {
        setState(() => _serviceLog.add('>>> 正在停止服务...'));
        result = await InstallerService.stopService();
      } else {
        setState(() => _serviceLog.add('>>> 正在启动服务...'));
        result = await InstallerService.startService();
      }

      if (!mounted) return;
      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      if (stdout.isNotEmpty) setState(() => _serviceLog.add(stdout));
      if (stderr.isNotEmpty) setState(() => _serviceLog.add(stderr));

      if (result.exitCode == 0) {
        setState(() => _serviceLog.add(_serviceRunning ? '✓ 服务已停止' : '✓ 服务已启动'));
        await Future.delayed(const Duration(seconds: 2));
        await _checkServiceStatus();
      } else {
        setState(() => _serviceLog.add('✗ 操作失败 (exit: ${result.exitCode})'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _serviceLog.add('错误: $e'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'COMMAND CENTER',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: CicadaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedBuilder(
                    animation: _cursorOpacity,
                    builder: (context, _) => Opacity(
                      opacity: _cursorOpacity.value,
                      child: const Text(
                        '_',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: CicadaColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _serviceRunning ? CicadaColors.ok : CicadaColors.alert,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _serviceRunning ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: _serviceRunning ? CicadaColors.ok : CicadaColors.alert,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Main service card (hero)
          ScanLineOverlay(
            child: HudPanel(
              title: 'SERVICE CONTROL',
              titleIcon: Icons.cloud,
              accent: _serviceRunning ? CicadaColors.energy : CicadaColors.alert,
              showGrid: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      // Diamond status indicator
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Transform.rotate(
                            angle: 0.785398, // 45 degrees in radians
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _serviceRunning
                                      ? CicadaColors.ok
                                      : CicadaColors.alert,
                                  width: 2,
                                ),
                                color: (_serviceRunning
                                        ? CicadaColors.ok
                                        : CicadaColors.alert)
                                    .withValues(alpha: 0.08),
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: -0.785398,
                                  child: Icon(
                                    _serviceRunning
                                        ? Icons.power
                                        : Icons.power_off,
                                    color: _serviceRunning
                                        ? CicadaColors.ok
                                        : CicadaColors.alert,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _serviceRunning ? '服务运行中' : '服务已停止',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _serviceRunning
                                    ? CicadaColors.ok
                                    : CicadaColors.alert,
                              ),
                            ),
                            if (_serviceRunning) ...[
                              Text(
                                'http://127.0.0.1:18789',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: CicadaColors.textTertiary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'UPTIME  $_uptimeString',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.2,
                                  color: CicadaColors.energy,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Tactical outlined button
                      SizedBox(
                        width: 140,
                        child: OutlinedButton.icon(
                          onPressed: _actionLoading ? null : _toggleService,
                          icon: _actionLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _serviceRunning
                                        ? CicadaColors.alert
                                        : CicadaColors.ok,
                                  ),
                                )
                              : Icon(
                                  _serviceRunning
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                ),
                          label: Text(_serviceRunning ? '停止' : '启动'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _serviceRunning
                                ? CicadaColors.alert
                                : CicadaColors.ok,
                            side: BorderSide(
                              color: _serviceRunning
                                  ? CicadaColors.alert
                                  : CicadaColors.ok,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info cards row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HudPanel(
                  title: 'SYS.INFO',
                  titleIcon: Icons.info_outline,
                  accent: CicadaColors.energy,
                  child: Column(
                    children: [
                      _envRow('Node.js', _nodeVersion),
                      const SizedBox(height: 8),
                      _envRow('OpenClaw', _openclawVersion),
                      const SizedBox(height: 8),
                      _envRow('Config', ConfigService.configPath),
                      const SizedBox(height: 8),
                      _envRow('OS', Platform.operatingSystemVersion),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HudPanel(
                  title: 'MODELS',
                  titleIcon: Icons.smart_toy,
                  accent: CicadaColors.data,
                  child: _configuredProviders.isEmpty
                      ? Text('暂未配置任何模型',
                          style:
                              TextStyle(color: CicadaColors.textTertiary))
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _configuredProviders
                              .map((p) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: CicadaColors.ok
                                              .withValues(alpha: 0.4)),
                                      borderRadius: BorderRadius.circular(4),
                                      color: CicadaColors.ok
                                          .withValues(alpha: 0.08),
                                    ),
                                    child: Text(p,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: CicadaColors.ok)),
                                  ))
                              .toList(),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick actions
          HudPanel(
            title: 'QUICK ACTIONS',
            titleIcon: Icons.bolt,
            accent: CicadaColors.accent,
            child: Row(
              children: [
                _actionButton(
                  icon: Icons.open_in_browser,
                  label: '打开面板',
                  onPressed: _serviceRunning
                      ? () => launchUrl(Uri.parse('http://127.0.0.1:18789/'))
                      : null,
                ),
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.terminal,
                  label: '打开终端',
                  onPressed: () {
                    if (Platform.isWindows) {
                      Process.run('cmd', ['/c', 'start', 'cmd']);
                    } else if (Platform.isMacOS) {
                      Process.run('open', ['-a', 'Terminal']);
                    } else if (Platform.isLinux) {
                      Process.run('x-terminal-emulator', []);
                    }
                  },
                ),
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.folder_open,
                  label: '配置目录',
                  onPressed: () {
                    final dir = ConfigService.configDir;
                    if (Platform.isWindows) {
                      Process.run('explorer', [dir.replaceAll('/', '\\')]);
                    } else if (Platform.isMacOS) {
                      Process.run('open', [dir]);
                    } else if (Platform.isLinux) {
                      Process.run('xdg-open', [dir]);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // System metrics panel
          HudPanel(
            title: 'SYSTEM METRICS',
            titleIcon: Icons.monitor_heart,
            accent: CicadaColors.data,
            showGrid: true,
            child: Row(
              children: [
                _metricCell('TIME', _clockString),
                const SizedBox(width: 24),
                _metricCell('PLATFORM', Platform.operatingSystem.toUpperCase()),
                const SizedBox(width: 24),
                _metricCell('MEMORY', 'N/A'),
                const SizedBox(width: 24),
                _metricCell(
                  'SERVICE',
                  _serviceRunning ? 'ACTIVE' : 'HALTED',
                  valueColor: _serviceRunning ? CicadaColors.ok : CicadaColors.alert,
                ),
              ],
            ),
          ),
          if (_serviceLog.isNotEmpty) ...[
            const SizedBox(height: 16),
            HudPanel(
              title: 'SERVICE LOG',
              titleIcon: Icons.terminal,
              accent: CicadaColors.muted,
              child: TerminalOutput(lines: _serviceLog, height: 150),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCell(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 1.5,
            color: CicadaColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            letterSpacing: 1.0,
            fontWeight: FontWeight.w700,
            color: valueColor ?? CicadaColors.energy,
          ),
        ),
      ],
    );
  }

  Widget _envRow(String label, String value) {
    return Row(
      children: [
        // Colored dot accent
        Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CicadaColors.energy,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              color: CicadaColors.textTertiary, fontSize: 12),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: CicadaColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return _TacticalButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
    );
  }
}

/// Tactical button with corner-cut clip (top-right corner)
class _TacticalButton extends StatefulWidget {
  const _TacticalButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_TacticalButton> createState() => _TacticalButtonState();
}

class _TacticalButtonState extends State<_TacticalButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final borderColor = disabled
        ? CicadaColors.muted.withValues(alpha: 0.3)
        : _hovered
            ? CicadaColors.accent
            : CicadaColors.accent.withValues(alpha: 0.5);
    final fgColor = disabled
        ? CicadaColors.textTertiary
        : _hovered
            ? CicadaColors.accent
            : CicadaColors.textSecondary;
    final bgColor = _hovered && !disabled
        ? CicadaColors.accent.withValues(alpha: 0.08)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: ClipPath(
          clipper: _CornerCutClipper(cutSize: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 12, color: fgColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerCutClipper extends CustomClipper<Path> {
  const _CornerCutClipper({required this.cutSize});
  final double cutSize;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - cutSize, 0)
      ..lineTo(size.width, cutSize)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CornerCutClipper old) =>
      cutSize != old.cutSize;
}
