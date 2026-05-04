enum MeshBackendId {
  netbird,
  tailscale,
}

extension MeshBackendIdX on MeshBackendId {
  String get configValue => switch (this) {
        MeshBackendId.netbird => 'netbird',
        MeshBackendId.tailscale => 'tailscale',
      };

  String get label => switch (this) {
        MeshBackendId.netbird => 'NetBird',
        MeshBackendId.tailscale => 'Tailscale',
      };

  String get description => switch (this) {
        MeshBackendId.netbird => '现代自建 WireGuard 组网，适合做主方案',
        MeshBackendId.tailscale => '成熟易用的设备组网，适合作为兼容方案',
      };

  String get docsUrl => switch (this) {
        MeshBackendId.netbird => 'https://github.com/netbirdio/netbird',
        MeshBackendId.tailscale => 'https://tailscale.com/',
      };

  String get detectCommand => switch (this) {
        MeshBackendId.netbird => 'netbird',
        MeshBackendId.tailscale => 'tailscale',
      };

  List<String> get detectArgs => const ['version'];

  static MeshBackendId? fromConfigValue(String? value) {
    return MeshBackendId.values.cast<MeshBackendId?>().firstWhere(
          (backend) => backend?.configValue == value,
          orElse: () => null,
        );
  }
}

class MeshBackendStatus {
  final MeshBackendId backend;
  final bool installed;
  final String version;
  final String detail;

  const MeshBackendStatus({
    required this.backend,
    required this.installed,
    required this.version,
    required this.detail,
  });
}
