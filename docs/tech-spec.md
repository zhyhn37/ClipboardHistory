# 技术规格说明

## 技术栈

| 层 | 选型 | 版本/要求 |
|----|------|-----------|
| 语言 | Swift | 5.9+ |
| UI 框架 | SwiftUI | macOS 13+ |
| 数据存储 | SQLite3 (系统内置 C API) | macOS 内置 |
| 图片存储 | 文件系统 | ~/Library/Application Support/ClipboardHistory/Images/ |
| 包管理 | Swift Package Manager (SPM) | 内置 |
| 最低系统 | macOS 13 Ventura | — |

## 项目配置

- **LSUIElement** = `YES`：纯菜单栏应用，不显示 Dock 图标
- **App Sandbox** = `NO`：需要访问全局剪贴板和模拟按键
- **Hardened Runtime** = `YES`：分发安全要求

## 架构

```
ClipboardHistoryApp (App 入口)
│
├── AppDelegate / MenuBarController
│   ├── NSStatusBar 菜单栏图标
│   ├── NSPopover 弹出窗口
│   ├── 全局快捷键 (NSEvent.addGlobalMonitor)
│   └── 右键菜单（设置 / 退出）
│
├── ClipboardMonitor (单例)
│   ├── Timer 每 0.5s 轮询 NSPasteboard.general
│   ├── changeCount 对比去重
│   └── 回调通知 DataStore 写入
│
├── DataStore (单例)
│   ├── DatabaseQueue (GRDB)
│   ├── CRUD 方法
│   ├── 搜索（SQL LIKE）
│   ├── 过期清理
│   └── 置顶切换
│
├── ImageStorage (单例)
│   ├── 图片写入磁盘
│   ├── 缩略图生成
│   └── 图片删除
│
└── Views/
    ├── ContentView（主界面容器）
    │   ├── SearchBar
    │   ├── 置顶区 (ForEach pinned items)
    │   ├── 历史区 (ForEach unpinned items)
    │   └── EmptyStateView
    │
    ├── ClipboardCard（单条卡片）
    │   ├── 文字卡片
    │   └── 图片卡片
    │
    └── SettingsView（设置窗口）
        ├── 存储时长 Picker
        └── 开机启动 Toggle
```

## 数据流

```
用户复制 → NSPasteboard 更新
    → ClipboardMonitor 检测变化
    → 读取内容 + 去重判断
    → DataStore.insert(item)
    → SQLite 写入 + (图片) 文件写入
    → UI 刷新（通过 @Published / Combine）
```

```
用户点击卡片 → 读取 DataStore
    → 内容写入 NSPasteboard.general
    → 模拟 Cmd+V 按键 (CGEvent)
    → 关闭 Popover
```

## 数据模型

```swift
struct ClipboardItem: Identifiable, Codable {
    var id: Int64
    var type: ItemType        // .text | .image
    var textContent: String?  // 文字内容
    var imagePath: String?    // 图片文件路径
    var timestamp: Date
    var isPinned: Bool
    var textPreview: String?  // 文字预览（前100字）
}

enum ItemType: String, Codable {
    case text
    case image
}
```

## 数据库表结构

```sql
CREATE TABLE clipboard_item (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,           -- 'text' | 'image'
    text_content TEXT,
    image_path TEXT,
    timestamp REAL NOT NULL,      -- TimeInterval since 1970
    is_pinned INTEGER DEFAULT 0,  -- 0 | 1
    text_preview TEXT
);

CREATE INDEX idx_timestamp ON clipboard_item(timestamp DESC);
CREATE INDEX idx_pinned ON clipboard_item(is_pinned);
```

## 关键 API 使用

- `NSPasteboard.general` — 读写系统剪贴板
- `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` — 全局快捷键
- `CGEvent(keyboardEventSource: .init(stateID: .combinedSessionState), ...)` — 模拟按键
- `SMAppService.mainApp().register()` — 开机启动注册
- `UserDefaults` — 存储设置（保留时长、开机启动开关）

## 目录结构

```
ClipboardHistory/
├── ClipboardHistoryApp.swift
├── MenuBarController.swift
├── ClipboardMonitor.swift
├── DataStore.swift
├── ImageStorage.swift
├── Models/
│   └── ClipboardItem.swift
├── Views/
│   ├── ContentView.swift
│   ├── ClipboardCard.swift
│   ├── SearchBar.swift
│   ├── SettingsView.swift
│   └── EmptyStateView.swift
├── Assets.xcassets/
│   └── AppIcon.icns
└── Info.plist (或 entitlements)
```
