import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/installer_service.dart';

part 'setup_state.g.dart';

/// Step status for three-state visualization
enum StepStatus {
  notStarted,
  inProgress,
  completed,
}

/// Setup state data model
class SetupStateData {
  final int currentStep;
  final bool nodeInstalled;
  final bool openclawInstalled;
  final bool detecting;
  final bool installing;
  final bool bundledAvailable;
  final String selectedMirror;
  final List<String> logLines;
  final String nodeVersion;
  final String clawVersion;
  final String bundledNodeVersion;
  final String bundledOpenClawVersion;

  const SetupStateData({
    required this.currentStep,
    required this.nodeInstalled,
    required this.openclawInstalled,
    required this.detecting,
    required this.installing,
    required this.bundledAvailable,
    required this.selectedMirror,
    required this.logLines,
    required this.nodeVersion,
    required this.clawVersion,
    required this.bundledNodeVersion,
    required this.bundledOpenClawVersion,
  });

  factory SetupStateData.initial() => const SetupStateData(
        currentStep: 0,
        nodeInstalled: false,
        openclawInstalled: false,
        detecting: true,
        installing: false,
        bundledAvailable: false,
        selectedMirror: 'https://registry.npmmirror.com',
        logLines: [],
        nodeVersion: '',
        clawVersion: '',
        bundledNodeVersion: '',
        bundledOpenClawVersion: '',
      );

  SetupStateData copyWith({
    int? currentStep,
    bool? nodeInstalled,
    bool? openclawInstalled,
    bool? detecting,
    bool? installing,
    bool? bundledAvailable,
    String? selectedMirror,
    List<String>? logLines,
    String? nodeVersion,
    String? clawVersion,
    String? bundledNodeVersion,
    String? bundledOpenClawVersion,
  }) {
    return SetupStateData(
      currentStep: currentStep ?? this.currentStep,
      nodeInstalled: nodeInstalled ?? this.nodeInstalled,
      openclawInstalled: openclawInstalled ?? this.openclawInstalled,
      detecting: detecting ?? this.detecting,
      installing: installing ?? this.installing,
      bundledAvailable: bundledAvailable ?? this.bundledAvailable,
      selectedMirror: selectedMirror ?? this.selectedMirror,
      logLines: logLines ?? this.logLines,
      nodeVersion: nodeVersion ?? this.nodeVersion,
      clawVersion: clawVersion ?? this.clawVersion,
      bundledNodeVersion: bundledNodeVersion ?? this.bundledNodeVersion,
      bundledOpenClawVersion:
          bundledOpenClawVersion ?? this.bundledOpenClawVersion,
    );
  }

  /// Get the adjusted step index accounting for bundled installation
  int get nodeStepIndex => bundledAvailable ? 1 : 2;
  int get openclawStepIndex => bundledAvailable ? 2 : 3;
  int get completeStepIndex => bundledAvailable ? 3 : 4;
  int get totalSteps => bundledAvailable ? 4 : 5;

  /// Calculate overall progress percentage
  double get overallProgress {
    final stepValue = 1.0 / totalSteps;
    var progress = 0.0;
    // Step 0 (detection) is always "completed" after detection
    progress += stepValue;
    // Network step (only if not bundled)
    if (!bundledAvailable) {
      if (currentStep >= 1) progress += stepValue;
    }
    // Node.js step
    if (currentStep >= nodeStepIndex || nodeInstalled) progress += stepValue;
    // OpenClaw step
    if (currentStep >= openclawStepIndex || openclawInstalled) {
      progress += stepValue;
    }
    // Complete step
    if (nodeInstalled && openclawInstalled) progress += stepValue;
    return progress.clamp(0.0, 1.0);
  }

  /// Get status for each step
  StepStatus getStepStatus(int step) {
    // Environment detection (always step 0)
    if (step == 0) {
      if (detecting) return StepStatus.inProgress;
      return StepStatus.completed;
    }

    // Network mode (only when bundled not available)
    if (!bundledAvailable && step == 1) {
      if (currentStep < 1) return StepStatus.notStarted;
      if (currentStep == 1) return StepStatus.inProgress;
      return StepStatus.completed;
    }

    // Node.js step
    if (step == nodeStepIndex) {
      if (currentStep < nodeStepIndex) return StepStatus.notStarted;
      if (nodeInstalled) return StepStatus.completed;
      if (currentStep == nodeStepIndex) return StepStatus.inProgress;
      return StepStatus.notStarted;
    }

    // OpenClaw step
    if (step == openclawStepIndex) {
      if (currentStep < openclawStepIndex) return StepStatus.notStarted;
      if (openclawInstalled) return StepStatus.completed;
      if (currentStep == openclawStepIndex) return StepStatus.inProgress;
      return StepStatus.notStarted;
    }

    // Complete step
    if (step == completeStepIndex) {
      if (currentStep < completeStepIndex) return StepStatus.notStarted;
      final allDone = nodeInstalled && openclawInstalled;
      return allDone ? StepStatus.completed : StepStatus.inProgress;
    }

    return StepStatus.notStarted;
  }
}

@riverpod
class SetupState extends _$SetupState {
  @override
  SetupStateData build() {
    // Auto-detect on initialization
    Future.microtask(() => detectEnvironment());
    return SetupStateData.initial();
  }

  Future<void> detectEnvironment() async {
    state = state.copyWith(detecting: true);

    final nodeResult = await InstallerService.checkNode();
    final clawResult = await InstallerService.checkOpenClaw();
    final bundledAvailable = await InstallerService.isBundledAvailable();
    final bundledVersions = await InstallerService.getBundledVersions();

    state = state.copyWith(
      nodeInstalled: nodeResult.exitCode == 0,
      openclawInstalled: clawResult.exitCode == 0,
      nodeVersion:
          nodeResult.exitCode == 0 ? (nodeResult.stdout as String).trim() : '',
      clawVersion: clawResult.exitCode == 0
          ? (clawResult.stdout as String).trim()
          : '',
      bundledAvailable: bundledAvailable,
      bundledNodeVersion: bundledVersions?['node'] ?? '',
      bundledOpenClawVersion: bundledVersions?['openclaw'] ?? '',
      detecting: false,
    );
  }

  Future<void> runInstall(
    Future<Process> Function() starter,
    String name,
  ) async {
    state = state.copyWith(
      installing: true,
      logLines: ['>>> 开始安装 $name ...'],
    );

    try {
      final exitCode = await InstallerService.runInstallWithCallback(
        starter,
        (line) {
          state = state.copyWith(
            logLines: [...state.logLines, line],
          );
        },
      );

      if (exitCode == 0) {
        state = state.copyWith(
          logLines: [...state.logLines, '\n✓ $name 安装成功'],
          installing: false,
        );
        await detectEnvironment();

        // Auto-advance to next step
        if (state.currentStep < 4) {
          await Future.delayed(const Duration(milliseconds: 500));
          state = state.copyWith(currentStep: state.currentStep + 1);
        }
      } else {
        state = state.copyWith(
          logLines: [
            ...state.logLines,
            '\n✗ 安装失败 (exit: $exitCode)',
            '提示：可尝试以管理员身份运行，或手动安装后点击"重新检测"',
          ],
          installing: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        logLines: [...state.logLines, '错误: $e'],
        installing: false,
      );
    }
  }

  Future<void> runBundledInstall({
    required bool isNode,
    required String name,
  }) async {
    state = state.copyWith(
      installing: true,
      logLines: ['>>> 开始离线安装 $name ...'],
    );

    try {
      final stream = isNode
          ? InstallerService.tryBundledInstallNodeJs()
          : InstallerService.tryBundledInstallOpenClaw(
              mirrorUrl: state.selectedMirror,
            );

      await for (final progress in stream) {
        final prefix = progress.percent >= 100
            ? '✓'
            : progress.percent > 0
                ? '●'
                : '○';
        state = state.copyWith(
          logLines: [
            ...state.logLines,
            '$prefix ${progress.step} (${progress.percent}%)',
          ],
        );
      }

      state = state.copyWith(
        logLines: [...state.logLines, '\n✓ $name 安装成功'],
        installing: false,
      );
      await detectEnvironment();

      // Auto-advance to next step
      if (state.currentStep < 4) {
        await Future.delayed(const Duration(milliseconds: 500));
        state = state.copyWith(currentStep: state.currentStep + 1);
      }
    } catch (e) {
      state = state.copyWith(
        logLines: [
          ...state.logLines,
          '\n✗ 安装失败: $e',
          '提示：可尝试以管理员身份运行，或手动安装后点击"重新检测"',
        ],
        installing: false,
      );
    }
  }

  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setSelectedMirror(String mirror) {
    state = state.copyWith(selectedMirror: mirror);
  }

  Future<void> runOnlineInstall({
    required bool isNode,
    required String name,
  }) async {
    final starter = isNode
        ? () => InstallerService.installNodejs(mirrorUrl: state.selectedMirror)
        : () => InstallerService.installOpenClaw(
              mirrorUrl: state.selectedMirror,
            );
    await runInstall(starter, name);
  }
}
