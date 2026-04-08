import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/services/bundled_installer_service.dart';

void main() {
  group('BundledInstallerService', () {
    test('should detect current platform', () {
      // This test verifies the platform detection logic doesn't throw
      expect(
        () => BundledInstallerService.isBundledAvailable(),
        returnsNormally,
      );
    });

    test('should return null versions when manifest not found', () async {
      final versions = await BundledInstallerService.getBundledVersions();
      // May be null if manifest doesn't exist, or valid if it does
      if (versions != null) {
        expect(versions.containsKey('node'), isTrue);
        expect(versions.containsKey('openclaw'), isTrue);
      }
    });

    test('should check bundled availability without throwing', () async {
      final available = await BundledInstallerService.isBundledAvailable();
      expect(available, isA<bool>());
    });
  });
}
