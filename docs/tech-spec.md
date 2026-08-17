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
│   ├── SQLite3 原生 C API
│   ├── CRUD + 合并插入方法
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
        ├── 存储时长说明（固定 3 天）
        └── 开机启动 Toggle
```

## 数据流

```
用户复制 → NSPasteboard 更新
    → ClipboardMonitor 检测变化
    → 读取内容 + 合并判定（存在则刷新时间戳）
    → DataStore.insertOrMerge(item)
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
    var contentHash: String?  // 图片像素哈希（重复合并判定，仅图片有值）
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
    text_preview TEXT,
    content_hash TEXT             -- 图片像素 SHA256，重复合并判定
);

CREATE INDEX idx_timestamp ON clipboard_item(timestamp DESC);
CREATE INDEX idx_pinned ON clipboard_item(is_pinned);
CREATE INDEX idx_content_hash ON clipboard_item(content_hash);
CREATE INDEX idx_text_content ON clipboard_item(text_content);
```

## 数据库迁移

无迁移框架，采用幂等轻量迁移（`DataStore.migrateIfNeeded`）：

1. 建表 SQL 直接包含最新列定义（新装即最新结构）
2. 启动时用 `PRAGMA table_info` 检查缺失列，`ALTER TABLE ADD COLUMN` 补齐
3. 索引用 `CREATE INDEX IF NOT EXISTS` 幂等创建

## 已知限制

- 升级前已存在的图片条目 `content_hash` 为 NULL，不参与重复合并，3 天内自然过期
- 升级前已有的重复数据不做全库去重，仅新复制时合并最新一条

## 关键 API 使用

- `NSPasteboard.general` — 读写系统剪贴板
- `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` — 全局快捷键
- `CGEvent(keyboardEventSource: .init(stateID: .combinedSessionState), ...)` — 模拟按键
- `SMAppService.mainApp().register()` — 开机启动注册
- `CryptoKit SHA256` — 图片像素哈希（重复合并判定，跨会话稳定）
- `UserDefaults` — 存储设置（开机启动开关）

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
