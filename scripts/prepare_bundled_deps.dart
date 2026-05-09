#!/usr/bin/env dart
// prepare_bundled_deps.dart - Downloads Node.js and OpenClaw for offline installation
// Usage: dart scripts/prepare_bundled_deps.dart

import 'dart:convert';
import 'dart:io';

const String nodeVersion = '22.14.0';
const String openclawVersion = '0.1.8';

final List<NodeJsPlatform> platforms = [
  NodeJsPlatform(
    name: 'win-x64',
    archiveName: 'node-v$nodeVersion-win-x64.zip',
    url: 'https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-win-x64.zip',
    binPath: 'node.exe',
    npmPath: 'npm.cmd',
  ),
  NodeJsPlatform(
    name: 'darwin-arm64',
    archiveName: 'node-v$nodeVersion-darwin-arm64.tar.gz',
    url: 'https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-darwin-arm64.tar.gz',
    binPath: 'bin/node',
    npmPath: 'bin/npm',
  ),
  NodeJsPlatform(
    name: 'darwin-x64',
    archiveName: 'node-v$nodeVersion-darwin-x64.tar.gz',
    url: 'https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-darwin-x64.tar.gz',
    binPath: 'bin/node',
    npmPath: 'bin/npm',
  ),
  NodeJsPlatform(
    name: 'linux-x64',
    archiveName: 'node-v$nodeVersion-linux-x64.tar.xz',
    url: 'https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-linux-x64.tar.xz',
    binPath: 'bin/node',
    npmPath: 'bin/npm',
  ),
];

class NodeJsPlatform {
  final String name;
  final String archiveName;
  final String url;
  final String binPath;
  final String npmPath;

  const NodeJsPlatform({
    required this.name,
    required this.archiveName,
    required this.url,
    required this.binPath,
    required this.npmPath,
  });
}

class BundledDepsPreparer {
  final String assetsDir = 'assets/bundled';
  final String nodeDir = 'assets/bundled/nodejs';

  Future<void> run() async {
    print('🚀 Preparing bundled dependencies...');
    print('   Node.js version: $nodeVersion');
    print('   OpenClaw version: $openclawVersion');
    print('');

    // Create directories
    await Directory(nodeDir).create(recursive: true);

    // Download Node.js for all platforms
    for (final platform in platforms) {
      await _downloadNodeJs(platform);
    }

    // npm pack OpenClaw
    await _packOpenClaw();

    // Create manifest
    await _createManifest();

    print('');
    print('✅ All bundled dependencies prepared successfully!');
    print('   Location: $assetsDir/');
    await _printSizeStats();
  }

  Future<void> _printSizeStats() async {
    var totalSize = 0;
    final dir = Directory(assetsDir);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    print('   Total size: ${_formatBytes(totalSize)}');
    print('');
    print('💡 Next steps:');
    print('   1. Build: flutter build <platform> --release');
    print('   2. Or use: dart scripts/build_with_bundled.dart');
  }

  Future<void> _downloadNodeJs(NodeJsPlatform platform) async {
    final filePath = '$nodeDir/${platform.archiveName}';
    final file = File(filePath);

    if (await file.exists()) {
      print('  ✓ ${platform.name}: Already exists (${platform.archiveName})');
      return;
    }

    print('  ↓ ${platform.name}: Downloading from ${platform.url}...');

    try {
      final request = await HttpClient().getUrl(Uri.parse(platform.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();

      final size = await file.length();
      print('  ✓ ${platform.name}: Downloaded (${_formatBytes(size)})');
    } catch (e) {
      print('  ✗ ${platform.name}: Failed - $e');
      // Clean up partial download
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _packOpenClaw() async {
    final tgzPath = '$assetsDir/openclaw-$openclawVersion.tgz';
    final file = File(tgzPath);

    if (await file.exists()) {
      print('  ✓ OpenClaw: Already exists (openclaw-$openclawVersion.tgz)');
      return;
    }

    print('  ↓ OpenClaw: Running npm pack openclaw@$openclawVersion...');

    // Try to use system npm
    try {
      final result = await Process.run(
        'npm',
        ['pack', 'openclaw@$openclawVersion'],
        workingDirectory: assetsDir,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        // Rename to standard name
        final packedFile = '$assetsDir/openclaw-$openclawVersion.tgz';
        if (await File(packedFile).exists()) {
          print('  ✓ OpenClaw: Packed successfully (openclaw-$openclawVersion.tgz)');
        } else {
          // Find the actual packed file and rename it
          final dir = Directory(assetsDir);
          await for (final entity in dir.list()) {
            if (entity is File && entity.path.endsWith('.tgz') && entity.path.contains('openclaw')) {
              await entity.rename(packedFile);
              print('  ✓ OpenClaw: Packed and renamed to openclaw-$openclawVersion.tgz');
              break;
            }
          }
        }
      } else {
        print('  ✗ OpenClaw: npm pack failed - ${result.stderr}');
        print('    You may need to install Node.js to build the offline package.');
      }
    } catch (e) {
      print('  ✗ OpenClaw: Failed - $e');
      print('    You may need to install Node.js to build the offline package.');
    }
  }

  Future<void> _createManifest() async {
    final manifest = {
      'nodeVersion': nodeVersion,
      'openclawVersion': openclawVersion,
      'platforms': platforms.map((p) => {
        'name': p.name,
        'archive': 'nodejs/${p.archiveName}',
        'binPath': p.binPath,
        'npmPath': p.npmPath,
      }).toList(),
      'openclaw': {
        'package': 'openclaw-$openclawVersion.tgz',
        'version': openclawVersion,
      },
    };

    final manifestFile = File('$assetsDir/manifest.json');
    await manifestFile.writeAsString(JsonEncoder.withIndent('  ').convert(manifest));
    print('  ✓ Created manifest.json');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

void main() async {
  final preparer = BundledDepsPreparer();
  await preparer.run();
}
