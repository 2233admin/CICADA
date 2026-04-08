import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/cicada_colors.dart';
import '../logic/setup_state.dart';

/// Environment detection widget
class EnvironmentDetector extends ConsumerWidget {
  const EnvironmentDetector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupStateProvider);
    final notifier = ref.read(setupStateProvider.notifier);

    return Card(
      color: CicadaColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '环境检测',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '正在检测系统环境...',
              style: TextStyle(color: CicadaColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildCheckItem(
              'Node.js',
              state.nodeInstalled,
              state.nodeVersion,
            ),
            const SizedBox(height: 12),
            _buildCheckItem(
              'OpenClaw',
              state.openclawInstalled,
              state.clawVersion,
            ),
            if (state.bundledAvailable) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CicadaColors.info.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CicadaColors.info),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.offline_bolt,
                      color: CicadaColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '离线安装包可用',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CicadaColors.info,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Node.js ${state.bundledNodeVersion} | OpenClaw ${state.bundledOpenClawVersion}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CicadaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (state.detecting)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: notifier.detectEnvironment,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新检测'),
                  ),
                  const SizedBox(width: 12),
                  if (!state.nodeInstalled || !state.openclawInstalled)
                    ElevatedButton(
                      onPressed: () => notifier.setCurrentStep(
                        state.bundledAvailable ? 1 : 2,
                      ),
                      child: const Text('继续安装'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String name, bool installed, String version) {
    return Row(
      children: [
        Icon(
          installed ? Icons.check_circle : Icons.cancel,
          color: installed ? CicadaColors.ok : CicadaColors.error,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (version.isNotEmpty)
                Text(
                  version,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CicadaColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: installed
                ? CicadaColors.ok.withAlpha(40)
                : CicadaColors.error.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            installed ? '已安装' : '未安装',
            style: TextStyle(
              fontSize: 12,
              color: installed ? CicadaColors.ok : CicadaColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
