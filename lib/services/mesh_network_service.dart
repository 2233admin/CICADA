import 'dart:io';

import '../models/mesh_backend.dart';
import 'config_service.dart';

class MeshNetworkingState {
  final MeshBackendId preferredBackend;
  final List<MeshBackendId> enabledBackends;
  final List<MeshBackendStatus> statuses;

  const MeshNetworkingState({
    required this.preferredBackend,
    required this.enabledBackends,
    required this.statuses,
  });

  MeshBackendStatus statusFor(MeshBackendId backend) {
    return statuses.firstWhere(
      (status) => status.backend == backend,
      orElse: () => MeshBackendStatus(
        backend: backend,
        installed: false,
        version: '',
        detail: '未检测',
      ),
    );
  }
}

class MeshNetworkService {
  static Future<MeshBackendStatus> detectBackend(MeshBackendId backend) async {
    try {
      final result = await Process.run(
        backend.detectCommand,
        backend.detectArgs,
        runInShell: true,
      );
      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();
      if (result.exitCode == 0) {
        return MeshBackendStatus(
          backend: backend,
          installed: true,
          version: stdout.split('\n').first.trim(),
          detail: stdout.isNotEmpty ? stdout : '已安装',
        );
      }
      return MeshBackendStatus(
        backend: backend,
        installed: false,
        version: '',
        detail: stderr.isNotEmpty ? stderr : '未安装',
      );
    } catch (e) {
      return MeshBackendStatus(
        backend: backend,
        installed: false,
        version: '',
        detail: e.toString(),
      );
    }
  }

  static Future<MeshNetworkingState> loadState() async {
    final preferredBackend = await ConfigService.getPreferredMeshBackend();
    final enabledBackends = await ConfigService.getEnabledMeshBackends();
    final statuses = await Future.wait(
      MeshBackendId.values.map(detectBackend),
    );

    return MeshNetworkingState(
      preferredBackend: preferredBackend,
      enabledBackends: enabledBackends,
      statuses: statuses,
    );
  }

  static Future<void> saveState({
    required MeshBackendId preferredBackend,
    required List<MeshBackendId> enabledBackends,
  }) async {
    await ConfigService.saveMeshNetworking(
      preferredBackend: preferredBackend,
      enabledBackends: enabledBackends,
    );
  }
}
