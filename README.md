# Flashcard

macOS 菜单栏英语闪卡工具，在系统菜单栏常驻，支持单词展示、发音（有道 API）、词库管理。

## 功能

- 菜单栏常驻闪卡窗口，浮动在最前方
- 单词卡片：显示单词、英式/美式音标、释义、例句
- 有道发音 API（英音/美音）
- 设置页面：词库列表、搜索、下载、启用/禁用
- 首次启动自动复制初始配置和词库

## 构建要求

- macOS 13+
- Xcode 15（Swift 5.10）
- 默认 CLT 工具链与项目不兼容，必须使用 Xcode 15

## 构建与运行

```bash
make build      # 编译
make run        # 编译并运行（菜单栏启动）
make app        # 生成 Flashcard.app
make dmg        # 生成 DMG 安装包（Flashcard-Installer.dmg）
make install    # 安装到 /Applications
make run-app    # 生成 .app 并打开
```

## 目录结构

```
Flashcard.app/              # 构建产物
Resources/
├── Info.plist              # 应用配置
├── config.json             # 初始配置文件
└── libs/                   # 初始词库
Sources/Flashcard/
├── FlashcardApp.swift      # 入口 + 窗口管理
├── ContentView.swift       # 单词卡片 UI
├── SettingsView.swift      # 设置页面
├── AppViewModel.swift      # 中央状态管理
├── Models.swift            # 数据模型
├── AudioService.swift      # 发音播放
├── LibraryService.swift    # 词库下载/加载
└── ConfigService.swift     # 配置读写
```
