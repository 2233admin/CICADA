#!/usr/bin/env dart
// clean_bundled.dart - 清理下载的离线资源
// Usage: dart scripts/clean_bundled.dart

import 'dart:io';

const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String reset = '\x1B[0m';

void log(String msg, {String? color}) {
  print('${color ?? ''}$msg$reset');
}

Future<void> main() async {
  log('🧹 清理离线资源工具\n', color: blue);

  final bundledDir = Directory('assets/bundled');
  if (!await bundledDir.exists()) {
    log('✓ 没有需要清理的内容', color: green);
    return;
  }

  var deletedCount = 0;
  var preservedCount = 0;
  var totalFreed = 0;

  // 遍历 bundled 目录
  await for (final entity in bundledDir.list()) {
    final name = entity.path.split('/').last.split('\\').last;

    // 保留 manifest.json
    if (name == 'manifest.json') {
      log('  ○ 保留: $name', color: yellow);
      preservedCount++;
      continue;
    }

    // 删除其他文件和目录
    if (entity is File) {
      final size = await entity.length();
      totalFreed += size;
      await entity.delete();
      log('  🗑️  删除: $name (${_formatBytes(size)})', color: red);
      deletedCount++;
    } else if (entity is Directory) {
      final size = await _getDirSize(entity);
      totalFreed += size;
      await entity.delete(recursive: true);
      log('  🗑️  删除: $name/ (${_formatBytes(size)})', color: red);
      deletedCount++;
    }
  }

  log('');
  log('✅ 清理完成!', color: green);
  log('   删除: $deletedCount 项', color: green);
  log('   保留: $preservedCount 项 (manifest.json)', color: green);
  log('   释放空间: ${_formatBytes(totalFreed)}', color: green);
}

Future<int> _getDirSize(Directory dir) async {
  var size = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      size += await entity.length();
    }
  }
  return size;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
