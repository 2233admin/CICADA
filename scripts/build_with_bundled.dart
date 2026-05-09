#!/usr/bin/env dart
// build_with_bundled.dart - 一键构建带离线资源的 CICADA
// Usage: dart scripts/build_with_bundled.dart [platform]
// Platforms: macos, windows, linux (default: current platform)

import 'dart:io';

const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String reset = '\x1B[0m';

void log(String msg, {String? color}) {
  print('${color ?? ''}$msg$reset');
}

Future<void> main(List<String> args) async {
  final platform = args.isNotEmpty ? args.first : _detectPlatform();

  log('🚀 CICADA 离线安装包构建工具', color: blue);
  log('   目标平台: $platform\n');

  // 步骤1: 准备离线资源
  log('📦 步骤 1/3: 准备离线资源...', color: blue);
  final prepareResult = await _runCommand(
    'dart',
    ['scripts/prepare_bundled_deps.dart'],
  );
  if (prepareResult != 0) {
    log('⚠️  准备离线资源时出现问题，继续构建...', color: yellow);
  }

  // 步骤2: 获取依赖
  log('\n📦 步骤 2/3: 获取 Flutter 依赖...', color: blue);
  final pubResult = await _runCommand('flutter', ['pub', 'get']);
  if (pubResult != 0) {
    log('❌ 获取依赖失败', color: red);
    exit(1);
  }

  // 步骤3: 构建
  log('\n📦 步骤 3/3: 构建应用...', color: blue);
  final buildArgs = ['build', platform, '--release'];

  // macOS 需要额外的代码签名处理
  if (platform == 'macos') {
    log('   注意: macOS 构建可能需要处理代码签名', color: yellow);
  }

  final buildResult = await _runCommand('flutter', buildArgs);
  if (buildResult != 0) {
    log('❌ 构建失败', color: red);
    exit(1);
  }

  // 完成
  log('\n✅ 构建完成!', color: green);
  log('   输出目录: build/${platform}/', color: green);

  // 显示打包说明
  _showPackageInstructions(platform);
}

String _detectPlatform() {
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

Future<int> _runCommand(String executable, List<String> args) async {
  final process = await Process.start(
    executable,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

void _showPackageInstructions(String platform) {
  log('\n📋 打包说明:', color: blue);

  switch (platform) {
    case 'macos':
      log('''
   macOS 应用打包:
   1. 找到 .app 文件: build/macos/Build/Products/Release/CICADA.app
   2. 可选: 签名应用
      codesign --force --deep --sign "Developer ID" CICADA.app
   3. 创建 dmg:
      hdiutil create -volname "CICADA" -srcfolder CICADA.app -ov -format UDZO CICADA.dmg
''');
      break;
    case 'windows':
      log('''
   Windows 应用打包:
   1. 找到可执行文件: build/windows/x64/runner/Release/
   2. 使用 Inno Setup 或 WiX 创建安装程序
   3. 或直接打包为 zip:
      powershell Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "CICADA-windows.zip"
''');
      break;
    case 'linux':
      log('''
   Linux 应用打包:
   1. 找到可执行文件: build/linux/x64/release/bundle/
   2. 打包为 tar.gz:
      tar -czf CICADA-linux.tar.gz -C build/linux/x64/release/bundle .
''');
      break;
  }
}
