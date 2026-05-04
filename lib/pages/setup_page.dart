import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/mesh_backend.dart';
import '../services/installer_service.dart';
import '../services/mesh_network_service.dart';
import '../widgets/terminal_output.dart';

class SetupPage extends StatefulWidget {
  final VoidCallback? onSetupComplete;

  const SetupPage({super.key, this.onSetupComplete});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  static const int _lastStepIndex = 5;

  int _currentStep = 0;
  bool _nodeInstalled = false;
  bool _openclawInstalled = false;
  bool _detecting = true;
  bool _installing = false;
  bool _online = true;
  String _selectedMirror = 'https://registry.npmmirror.com';
  final List<String> _logLines = [];
  String _nodeVersion = '';
  String _clawVersion = '';
  MeshBackendId _preferredMeshBackend = MeshBackendId.netbird;
  List<MeshBackendId> _enabledMeshBackends = [
    MeshBackendId.netbird,
    MeshBackendId.tailscale,
  ];
  Map<MeshBackendId, MeshBackendStatus> _meshStatuses = {
    for (final backend in MeshBackendId.values)
      backend: MeshBackendStatus(
        backend: backend,
        installed: false,
        version: '',
        detail: '未检测',
      ),
  };

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    final nodeResult = await InstallerService.checkNode();
    final clawResult = await InstallerService.checkOpenClaw();
    final meshState = await MeshNetworkService.loadState();
    if (!mounted) return;
    setState(() {
      _nodeInstalled = nodeResult.exitCode == 0;
      _openclawInstalled = clawResult.exitCode == 0;
      _nodeVersion = _nodeInstalled ? (nodeResult.stdout as String).trim() : '';
      _clawVersion = _openclawInstalled ? (clawResult.stdout as String).trim() : '';
      _preferredMeshBackend = meshState.preferredBackend;
      _enabledMeshBackends = meshState.enabledBackends;
      _meshStatuses = {
        for (final status in meshState.statuses) status.backend: status,
      };
      _detecting = false;
    });
  }

  bool get _meshReady {
    return _enabledMeshBackends.every(
      (backend) => (_meshStatuses[backend]?.installed ?? false),
    );
  }

  bool get _setupReady => _nodeInstalled && _openclawInstalled && _meshReady;

  Future<void> _saveMeshSelection() async {
    await MeshNetworkService.saveState(
      preferredBackend: _preferredMeshBackend,
      enabledBackends: _enabledMeshBackends,
    );
  }

  Future<void> _selectPreferredMeshBackend(MeshBackendId backend) async {
    setState(() {
      _preferredMeshBackend = backend;
      if (!_enabledMeshBackends.contains(backend)) {
        _enabledBackendsWith(backend);
      }
    });
    await _saveMeshSelection();
  }

  void _enabledBackendsWith(MeshBackendId backend) {
    _enabledMeshBackends = [
      ..._enabledMeshBackends.where((item) => item != backend),
      backend,
    ];
  }

  Future<void> _toggleMeshBackend(MeshBackendId backend, bool enabled) async {
    if (!enabled && backend == _preferredMeshBackend) {
      return;
    }
    setState(() {
      if (enabled) {
        _enabledBackendsWith(backend);
      } else {
        _enabledMeshBackends =
            _enabledMeshBackends.where((item) => item != backend).toList();
      }
    });
    await _saveMeshSelection();
  }

  Future<void> _runInstall(Future<Process> Function() starter, String name) async {
    setState(() {
      _installing = true;
      _logLines.clear();
      _logLines.add('>>> 开始安装 $name ...');
    });
    try {
      final exitCode = await InstallerService.runInstallWithCallback(
        starter,
        (line) {
          if (!mounted) return;
          setState(() => _logLines.add(line));
        },
      );
      if (!mounted) return;
      if (exitCode == 0) {
        setState(() {
          _logLines.add('\n✓ $name 安装成功');
          _installing = false;
        });
        await _detect();
        // Auto-advance to next step
        if (mounted && _currentStep < _lastStepIndex) {
          setState(() => _currentStep++);
        }
      } else {
        setState(() {
          _logLines.add('\n✗ 安装失败 (exit: $exitCode)');
          _logLines.add('提示：可尝试以管理员身份运行，或手动安装后点击"重新检测"');
          _installing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logLines.add('错误: $e');
        _installing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '安装向导',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_setupReady)
                Chip(
                  label: const Text('环境就绪'),
                  avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '跟随向导完成 OpenClaw 与组网组件安装，整个过程约 5 分钟',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < _lastStepIndex) setState(() => _currentStep++);
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (details.currentStep < _lastStepIndex)
                      FilledButton(
                        onPressed: details.onStepContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                        ),
                        child: const Text('下一步'),
                      ),
                    if (details.currentStep == _lastStepIndex && _setupReady)
                      FilledButton.icon(
                        onPressed: widget.onSetupComplete,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('前往模型配置'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                        ),
                      ),
                    if (details.currentStep > 0) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('上一步'),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('环境检测'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildDetectStep(),
              ),
              Step(
                title: const Text('网络模式'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildNetworkStep(),
              ),
              Step(
                title: const Text('组网方案'),
                isActive: _currentStep >= 2,
                state: _meshReady ? StepState.complete : StepState.indexed,
                content: _buildMeshStep(),
              ),
              Step(
                title: const Text('安装 Node.js'),
                isActive: _currentStep >= 3,
                state: _nodeInstalled ? StepState.complete : StepState.indexed,
                content: _buildInstallNodeStep(),
              ),
              Step(
                title: const Text('安装 OpenClaw'),
                isActive: _currentStep >= 4,
                state: _openclawInstalled ? StepState.complete : StepState.indexed,
                content: _buildInstallClawStep(),
              ),
              Step(
                title: const Text('完成'),
                isActive: _currentStep >= 5,
                content: _buildCompleteStep(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectStep() {
    if (_detecting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('正在检测环境...'),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _checkRow('Node.js', _nodeInstalled, _nodeVersion),
        const SizedBox(height: 8),
        _checkRow('OpenClaw', _openclawInstalled, _clawVersion),
        const SizedBox(height: 12),
        if (_nodeInstalled && _openclawInstalled)
          const Text('所有依赖已就绪，可直接跳到最后一步。',
              style: TextStyle(color: Colors.green)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _detect,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('重新检测'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
        ),
      ],
    );
  }

  Widget _checkRow(String name, bool ok, String version) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 8),
        Text('$name: ${ok ? "已安装" : "未安装"}'),
        if (version.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text('($version)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ],
    );
  }

  Widget _buildNetworkStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<bool>(
          groupValue: _online,
          onChanged: (v) => setState(() => _online = v ?? true),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: const Text('在线模式（推荐）'),
                subtitle: const Text('从互联网下载安装'),
                value: true,
              ),
              RadioListTile<bool>(
                title: const Text('离线模式'),
                subtitle: const Text('使用本地安装包'),
                value: false,
              ),
            ],
          ),
        ),
        if (_online) ...[
          const SizedBox(height: 12),
          const Text('NPM 镜像源:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _selectedMirror,
            onChanged: (v) => setState(() => _selectedMirror = v ?? _selectedMirror),
            child: Column(
              children: {
                '淘宝镜像（推荐）': 'https://registry.npmmirror.com',
                '腾讯镜像': 'https://mirrors.cloud.tencent.com/npm/',
                '华为镜像': 'https://repo.huaweicloud.com/repository/npm/',
              }.entries.map(
                (e) => RadioListTile<String>(
                  title: Text(e.key),
                  subtitle: Text(e.value, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  value: e.value,
                  dense: true,
                ),
              ).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInstallNodeStep() {
    if (_nodeInstalled) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text('Node.js 已安装 ($_nodeVersion)，跳过此步骤'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('将通过 winget 自动安装 Node.js LTS 版本'),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _installing
                  ? null
                  : () => _runInstall(
                        () => InstallerService.installNodejs(),
                        'Node.js',
                      ),
              icon: _installing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              label: Text(_installing ? '安装中...' : '安装 Node.js'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _installing ? null : _detect,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('已手动安装？重新检测'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF30363D)),
              ),
            ),
          ],
        ),
        if (_logLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          TerminalOutput(lines: _logLines),
        ],
      ],
    );
  }

  Widget _buildMeshStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '默认主方案为 ${_preferredMeshBackend.label}，建议至少安装一个组网后端。',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        ...MeshBackendId.values.map(_buildMeshBackendTile),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _detecting ? null : _detect,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('重新检测组网环境'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
        ),
        if (_logLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          TerminalOutput(lines: _logLines),
        ],
      ],
    );
  }

  Widget _buildMeshBackendTile(MeshBackendId backend) {
    final status = _meshStatuses[backend] ??
        MeshBackendStatus(
          backend: backend,
          installed: false,
          version: '',
          detail: '未检测',
        );
    final enabled = _enabledMeshBackends.contains(backend);
    final preferred = _preferredMeshBackend == backend;
    final isInstallingThisBackend =
        _installing && _logLines.any((line) => line.contains(backend.label));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: preferred ? const Color(0xFF7C3AED) : const Color(0xFF30363D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: enabled,
                onChanged: preferred
                    ? null
                    : (value) => _toggleMeshBackend(backend, value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          backend.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(status.installed ? '已安装' : '未安装'),
                          avatar: Icon(
                            status.installed ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: status.installed ? Colors.green : Colors.red,
                          ),
                          backgroundColor: (status.installed ? Colors.green : Colors.red)
                              .withValues(alpha: 0.12),
                          side: BorderSide.none,
                        ),
                        if (preferred) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('主方案'),
                            backgroundColor:
                                const Color(0xFF7C3AED).withValues(alpha: 0.2),
                            side: BorderSide.none,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      backend.description,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    if (status.version.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        status.version,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      status.detail,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: !enabled || status.installed || _installing
                    ? null
                    : () => _runInstall(
                          () => InstallerService.installMeshBackend(backend),
                          backend.label,
                        ),
                icon: isInstallingThisBackend
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  status.installed ? '${backend.label} 已安装' : '安装 ${backend.label}',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                ),
              ),
              OutlinedButton.icon(
                onPressed: preferred ? null : () => _selectPreferredMeshBackend(backend),
                icon: const Icon(Icons.flag, size: 16),
                label: const Text('设为主方案'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Text(
                  backend.docsUrl,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallClawStep() {
    if (_openclawInstalled) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text('OpenClaw 已安装 ($_clawVersion)，跳过此步骤'),
        ],
      );
    }
    if (!_nodeInstalled) {
      return const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('请先安装 Node.js'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('将通过 npm 安装 OpenClaw${_online ? "（使用 ${_selectedMirror.split("/").last} 镜像）" : ""}'),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _installing
                  ? null
                  : () => _runInstall(
                        () => InstallerService.installOpenClaw(
                          mirrorUrl: _online ? _selectedMirror : null,
                        ),
                        'OpenClaw',
                      ),
              icon: _installing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              label: Text(_installing ? '安装中...' : '安装 OpenClaw'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _installing ? null : _detect,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重新检测'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF30363D)),
              ),
            ),
          ],
        ),
        if (_logLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          TerminalOutput(lines: _logLines),
        ],
      ],
    );
  }

  Widget _buildCompleteStep() {
    final allDone = _setupReady;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          allDone ? Icons.celebration : Icons.warning_amber,
          size: 48,
          color: allDone ? Colors.amber : Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          allDone ? '环境准备就绪！' : '部分组件尚未安装，请返回完成安装。',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (allDone) ...[
          const SizedBox(height: 8),
          Text('当前主组网方案：${_preferredMeshBackend.label}'),
          const SizedBox(height: 4),
          const Text('接下来请前往「模型配置」页面，配置至少一个 AI 模型提供商。'),
          const SizedBox(height: 4),
          Text(
            '推荐：智谱 GLM-4 Flash（完全免费）',
            style: TextStyle(color: Colors.green[300], fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
