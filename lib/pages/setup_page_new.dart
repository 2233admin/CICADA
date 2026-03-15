import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_stepper/easy_stepper.dart';
import '../app/theme/cicada_colors.dart';
import 'setup/logic/setup_state.dart';
import 'setup/widgets/environment_detector.dart';
import 'setup/widgets/installation_panel.dart';

/// Setup page with step-by-step wizard
class SetupPageNew extends ConsumerWidget {
  final VoidCallback? onSetupComplete;

  const SetupPageNew({super.key, this.onSetupComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupStateProvider);
    final notifier = ref.read(setupStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(state),
          const SizedBox(height: 8),
          const Text(
            '跟随向导完成 OpenClaw 安装，整个过程约 5 分钟',
            style: TextStyle(color: CicadaColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Overall progress
          _buildOverallProgress(state),
          const SizedBox(height: 32),

          // Stepper
          EasyStepper(
            activeStep: state.currentStep,
            lineStyle: const LineStyle(
              lineLength: 70,
              lineType: LineType.normal,
              lineThickness: 3,
              defaultLineColor: Colors.grey,
              finishedLineColor: CicadaColors.data,
            ),
            activeStepTextColor: CicadaColors.data,
            finishedStepTextColor: CicadaColors.ok,
            internalPadding: 0,
            showLoadingAnimation: false,
            stepRadius: 24,
            showStepBorder: false,
            steps: _buildSteps(state),
            onStepReached: (index) => notifier.setCurrentStep(index),
          ),
          const SizedBox(height: 32),

          // Current step content
          _buildCurrentStepContent(state),
        ],
      ),
    );
  }

  Widget _buildHeader(SetupStateData state) {
    return Row(
      children: [
        const Text(
          'SETUP WIZARD',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        if (state.nodeInstalled && state.openclawInstalled)
          Chip(
            label: const Text('环境就绪'),
            avatar: const Icon(
              Icons.check_circle,
              size: 16,
              color: CicadaColors.ok,
            ),
            backgroundColor: CicadaColors.ok.withAlpha(40),
            side: BorderSide.none,
          ),
      ],
    );
  }

  Widget _buildOverallProgress(SetupStateData state) {
    final progress = state.overallProgress;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '总体进度',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CicadaColors.data,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(
                CicadaColors.data,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<EasyStep> _buildSteps(SetupStateData state) {
    final steps = <EasyStep>[
      EasyStep(
        customStep: _buildStepIcon(0, state),
        title: '环境检测',
      ),
    ];

    if (!state.bundledAvailable) {
      steps.add(
        EasyStep(
          customStep: _buildStepIcon(1, state),
          title: '网络配置',
        ),
      );
    }

    steps.addAll([
      EasyStep(
        customStep: _buildStepIcon(state.nodeStepIndex, state),
        title: 'Node.js',
      ),
      EasyStep(
        customStep: _buildStepIcon(state.openclawStepIndex, state),
        title: 'OpenClaw',
      ),
      EasyStep(
        customStep: _buildStepIcon(state.completeStepIndex, state),
        title: '完成',
      ),
    ]);

    return steps;
  }

  Widget _buildStepIcon(int step, SetupStateData state) {
    final status = state.getStepStatus(step);
    final isCurrent = state.currentStep == step;

    Color color;
    IconData icon;

    switch (status) {
      case StepStatus.completed:
        color = CicadaColors.ok;
        icon = Icons.check_circle;
        break;
      case StepStatus.inProgress:
        color = isCurrent ? CicadaColors.data : CicadaColors.accent;
        icon = Icons.radio_button_checked;
        break;
      case StepStatus.notStarted:
        color = Colors.grey;
        icon = Icons.radio_button_unchecked;
        break;
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withAlpha(40),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildCurrentStepContent(SetupStateData state) {
    // Step 0: Environment detection
    if (state.currentStep == 0) {
      return const EnvironmentDetector();
    }

    // Network configuration step (only if bundled not available)
    if (!state.bundledAvailable && state.currentStep == 1) {
      return _buildNetworkStep(state);
    }

    // Node.js installation
    if (state.currentStep == state.nodeStepIndex) {
      return InstallationPanel(
        title: 'Node.js',
        description: 'Node.js 是运行 OpenClaw 的必需环境',
        isNode: true,
        useBundled: state.bundledAvailable,
      );
    }

    // OpenClaw installation
    if (state.currentStep == state.openclawStepIndex) {
      return InstallationPanel(
        title: 'OpenClaw',
        description: 'OpenClaw 核心组件',
        isNode: false,
        useBundled: state.bundledAvailable,
      );
    }

    // Complete step
    if (state.currentStep == state.completeStepIndex) {
      return _buildCompleteStep(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildNetworkStep(SetupStateData state) {
    return Card(
      color: CicadaColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '网络配置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '选择 npm 镜像源以加速下载',
              style: TextStyle(color: CicadaColors.textSecondary),
            ),
            const SizedBox(height: 24),
            // Mirror selection would go here
            const Text('镜像源选择功能待实现'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('下一步'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteStep(SetupStateData state) {
    final allDone = state.nodeInstalled && state.openclawInstalled;

    return Card(
      color: CicadaColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              allDone ? Icons.check_circle : Icons.pending,
              size: 64,
              color: allDone ? CicadaColors.ok : CicadaColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              allDone ? '安装完成！' : '等待安装完成...',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              allDone ? 'OpenClaw 已准备就绪' : '请完成所有安装步骤',
              style: const TextStyle(color: CicadaColors.textSecondary),
            ),
            if (allDone) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onSetupComplete,
                child: const Text('开始使用'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
