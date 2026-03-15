# CICADA 离线安装方案

## 概述

CICADA 支持离线安装，将 Node.js 和 OpenClaw 打包进应用，解决国内用户访问 npm/node 官方源慢或不稳定的问题。

## 技术方案

### 打包内容

| 组件 | 版本 | 大小(压缩后) |
|------|------|-------------|
| Node.js | 22.14.0 LTS | ~40MB |
| OpenClaw | 0.1.8 | ~5MB |
| **总计** | - | **~45MB/平台** |

### 支持平台

- Windows x64
- macOS x64 (Intel)
- macOS ARM64 (Apple Silicon)
- Linux x64

## 构建流程

### 1. 准备离线资源

```bash
dart scripts/prepare_bundled_deps.dart
```

此脚本会：
1. 下载 Node.js 22.x 所有平台的压缩包
2. 运行 `npm pack openclaw@0.1.8` 打包 OpenClaw
3. 生成 `manifest.json` 配置文件

下载的文件存放在：
- `assets/bundled/nodejs/` - Node.js 压缩包
- `assets/bundled/openclaw-0.1.8.tgz` - OpenClaw npm 包

### 2. 构建应用

```bash
# 开发构建
flutter build macos --debug

# 发布构建
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## 运行时行为

### 自动检测

应用启动时会自动检测：
1. 系统是否已安装 Node.js
2. 系统是否已安装 OpenClaw
3. 是否包含离线资源包

### 安装流程

**情况1：包含离线资源包（推荐）**
```
环境检测 → 解压 Node.js → 安装 OpenClaw → 完成
```

**情况2：不包含离线资源包**
```
环境检测 → 选择镜像源 → 在线安装 Node.js → 在线安装 OpenClaw → 完成
```

### 回退机制

如果离线安装失败，应用会自动回退到在线安装模式。

## 目录结构

```
assets/bundled/
├── manifest.json          # 资源配置清单
├── openclaw-0.1.8.tgz     # OpenClaw npm 包
└── nodejs/
    ├── node-v22.14.0-win-x64.zip
    ├── node-v22.14.0-darwin-arm64.tar.gz
    ├── node-v22.14.0-darwin-x64.tar.gz
    └── node-v22.14.0-linux-x64.tar.xz
```

## 运行时目录

离线资源解压到应用支持目录：

- **Windows**: `%APPDATA%/CICADA/bundled/`
- **macOS**: `~/Library/Application Support/CICADA/bundled/`
- **Linux**: `~/.local/share/CICADA/bundled/`

## CI/CD 集成

GitHub Actions 已配置自动准备离线资源：

```yaml
- name: Prepare bundled dependencies
  run: dart scripts/prepare_bundled_deps.dart
```

## 版本升级

### 升级 Node.js

修改 `scripts/prepare_bundled_deps.dart`：
```dart
const String nodeVersion = '22.x.x'; // 修改版本号
```

### 升级 OpenClaw

修改 `scripts/prepare_bundled_deps.dart`：
```dart
const String openclawVersion = '0.x.x'; // 修改版本号
```

然后重新运行准备脚本。

## 管理脚本

### 一键构建
```bash
dart scripts/build_with_bundled.dart [platform]
```

### 清理离线资源
```bash
dart scripts/clean_bundled.dart
```

### 仅准备资源（不构建）
```bash
dart scripts/prepare_bundled_deps.dart
```

## 故障排除

### 构建脚本下载失败

1. 检查网络连接
2. 使用代理：
   ```bash
   export HTTP_PROXY=http://127.0.0.1:7890
   export HTTPS_PROXY=http://127.0.0.1:7890
   dart scripts/prepare_bundled_deps.dart
   ```

### 运行时解压失败

1. 检查磁盘空间（需要约 150MB 空闲空间）
2. 检查写入权限
3. 查看应用日志获取详细错误信息

### 离线安装后找不到命令

离线安装的 Node.js 不会添加到系统 PATH，需要通过 `BundledInstallerService` 获取路径：

```dart
final nodePath = await BundledInstallerService.getNodePath();
final npmPath = await BundledInstallerService.getNpmPath();
```

## 体积优化

如果只需要支持特定平台，可以修改 `scripts/prepare_bundled_deps.dart`：

```dart
final List<NodeJsPlatform> platforms = [
  // 只保留需要的平台
  NodeJsPlatform(
    name: 'darwin-arm64',
    // ...
  ),
];
```

## 安全考虑

1. Node.js 二进制文件来自官方源 (nodejs.org)
2. OpenClaw 来自 npm registry
3. 建议验证下载文件的 checksum（可扩展脚本支持）
