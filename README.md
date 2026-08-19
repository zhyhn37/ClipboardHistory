# ClipboardHistory

macOS 菜单栏剪贴板历史管理工具。自动记录你复制过的一切内容（文字 + 图片），支持回溯、搜索、置顶与一键再次粘贴。轻量、纯本地运行，数据绝不上传。

> Swift + SwiftUI 开发 · SQLite 本地存储 · macOS 13 (Ventura) 及以上

## ✨ 功能特性

- **自动记录**：捕获每次 Cmd+C 的文本与图片，后台静默运行
- **智能去重**：重复内容合并为一条（文字按内容匹配，图片按 SHA256 像素哈希判定），连续复制相同内容不重复写库
- **历史浏览**：菜单栏弹出卡片式列表，按时间倒序，置顶条目置顶显示
- **实时搜索**：输入即过滤，模糊匹配
- **一键粘贴**：点击卡片即粘贴到当前应用，窗口自动收起；双击卡片可打开详情检视窗口
- **仅复制不粘贴**：把条目重新写回剪贴板而不触发粘贴，窗口保持打开
- **置顶与管理**：置顶 / 取消置顶、删除（带确认）
- **自动清理**：默认保留 3 天，置顶条目豁免清理
- **全局快捷键**：默认 `Cmd + Shift + V` 呼出 / 收起
- **开机自启**：可在设置中开关

## 🔒 隐私

所有剪贴板数据仅存储在本机 `~/Library/Application Support/ClipboardHistory/`，不上传任何网络，无任何数据采集。

## 🛠 构建与使用

需要 Xcode（macOS 13+）。

**方式一：Xcode 打开**

```bash
open ClipboardHistory/ClipboardHistory.xcodeproj
```

选择 `ClipboardHistory` scheme 直接 Run，或 Archive 后导出 `.app` 拖入「应用程序」。

**方式二：命令行构建**

```bash
cd ClipboardHistory
xcodebuild -project ClipboardHistory.xcodeproj -scheme ClipboardHistory -configuration Release build
```

构建产物位于 `ClipboardHistory/build/Build/Products/Release/ClipboardHistory.app`。

## 🧰 技术栈

- Swift 5.9 / SwiftUI + AppKit（菜单栏常驻，`LSUIElement`）
- SQLite 本地存储（文字 + 图片文件哈希去重）
- 架构：`ClipboardMonitor`（监听）→ `DataStore`（存储）→ `PasteController` / `DetailWindowController`（交互）

## 📚 项目文档

| 文档 | 说明 |
|------|------|
| [docs/requirements.md](docs/requirements.md) | 需求规格 |
| [docs/tech-spec.md](docs/tech-spec.md) | 技术选型、架构与数据模型 |
| [docs/design-spec.md](docs/design-spec.md) | UI 设计规范 |
| [docs/implementation-plan.md](docs/implementation-plan.md) | 分步执行计划与状态 |
| [docs/development-standards.md](docs/development-standards.md) | 开发规范 |
| [dev-logs/](dev-logs/) | 开发日志 |

## 🗺 路线图

- [ ] 富文本格式保留
- [ ] 快捷键自定义界面
- [ ] iCloud / 多设备同步
