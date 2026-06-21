# 开发规范

## 命名规范

### Swift 文件
- 文件名使用 PascalCase：`ClipboardMonitor.swift`
- 类型名使用 PascalCase：`struct ClipboardItem`
- 变量/函数使用 camelCase：`var isPinned`, `func insertItem()`
- 常量使用 camelCase（非全大写）：`let maxPreviewLength = 100`

### 文件组织
- 每个 Swift 文件只包含一个主要类型定义
- 相关的 extension 可以放在同一文件
- View 文件放在 `Views/` 子文件夹
- Model 文件放在 `Models/` 子文件夹
- 工具类放在 `Utils/` 子文件夹

## 代码风格

### 注释
```swift
/// 将内容写入系统剪贴板并模拟粘贴操作
/// - Parameter item: 要粘贴的剪贴板条目
func pasteItem(_ item: ClipboardItem) {
    // ...
}
```

- 公开方法使用 `///` 文档注释
- 复杂逻辑内部使用 `//` 行注释说明意图
- 不要注释显而易见的事情（如 `// 设置变量 x 为 1`）

### 空行与缩进
- 使用 4 空格缩进
- 类型定义之间空一行
- 方法之间空一行
- 逻辑段落之间空一行

### 结构
- 优先使用 `struct` 而非 `class`（SwiftUI 惯例）
- 单例使用 `static let shared = ...` 模式
- 避免强制解包（`!`），使用 `guard let` 或 `if let`

## Git 提交规范

提交信息格式：
```
<type>: <简短描述>

<详细说明（可选）>
```

类型：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具相关

示例：
```
feat: 实现剪贴板文字监听

- ClipboardMonitor 每 0.5s 轮询 NSPasteboard
- 相同连续内容自动去重
- 文字内容生成前100字预览
```

## 测试规范

- 每个 DataStore 方法手动验证后再写下一个
- UI 相关通过实际运行验证
- 修复 bug 时先复现再修复再验证

## 安全规范

- 不硬编码路径，使用 `FileManager.default.urls(for:in:)`
- 不记录用户剪贴板内容到日志
- 权限申请使用系统标准对话框
