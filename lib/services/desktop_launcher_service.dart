import 'dart:io';

class DesktopLauncherService {
  static Future<void> openTerminal() {
    return _runPlatformCommand(
      windows: ['cmd', '/c', 'start', 'cmd'],
      linux: ['x-terminal-emulator'],
      macos: ['open', '-a', 'Terminal'],
    );
  }

  static Future<void> openDirectory(String path) {
    return _runPlatformCommand(
      windows: ['explorer', path.replaceAll('/', '\\')],
      linux: ['xdg-open', path],
      macos: ['open', path],
    );
  }

  static Future<void> _runPlatformCommand({
    required List<String> windows,
    required List<String> linux,
    required List<String> macos,
  }) async {
    if (Platform.isWindows) {
      await Process.start(windows.first, windows.sublist(1), runInShell: true);
      return;
    }

    if (Platform.isLinux) {
      await Process.start(linux.first, linux.sublist(1), runInShell: true);
      return;
    }

    if (Platform.isMacOS) {
      await Process.start(macos.first, macos.sublist(1), runInShell: true);
      return;
    }

    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
