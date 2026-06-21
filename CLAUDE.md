# CLAUDE.md — ClipboardHistory 项目指引

## 项目概述

这是一个 macOS 菜单栏剪贴板历史管理工具。使用 Swift + SwiftUI 开发，SQLite 本地存储。

## 规范文档路径

在开始任何开发工作前，请先阅读以下规范文档：

| 文档 | 路径 | 说明 |
|------|------|------|
| 需求规格 | [`docs/requirements.md`](docs/requirements.md) | 功能和非功能需求 |
| 技术规格 | [`docs/tech-spec.md`](docs/tech-spec.md) | 技术选型、架构、数据模型 |
| 设计规范 | [`docs/design-spec.md`](docs/design-spec.md) | UI 颜色、字体、布局、交互 |
| 执行计划 | [`docs/implementation-plan.md`](docs/implementation-plan.md) | 分步执行步骤和状态跟踪 |
| 开发规范 | [`docs/development-standards.md`](docs/development-standards.md) | 命名、代码风格、提交规范 |

## 工作流程

### 每次开发前
1. 读取 [`docs/implementation-plan.md`](docs/implementation-plan.md) 确认当前阶段和下一步
2. 根据任务类型读取对应的规范文档（技术/设计）
3. 确认上一步验证已通过再继续

### 开发中
1. 严格按照分步计划执行，每步独立完成并验证
2. 匹配现有代码风格和命名规范
3. 不在一步中做太多事 — 保持增量推进

### 每天结束前
1. 更新 [`dev-logs/YYYY-MM-DD.md`](dev-logs/) 记录今日完成和明日待办
2. 更新 [`docs/implementation-plan.md`](docs/implementation-plan.md) 中的步骤状态

## 关键原则

1. **每步独立验证**：完成一个步骤后必须验证通过才进入下一步
2. **不跳步**：即使某步看起来简单也要完整执行
3. **破坏性操作需确认**：删除代码、修改数据库结构等先征得用户同意
4. **隐私优先**：所有剪贴板数据仅存本地，绝不上传

## 项目路径

- 项目根目录：`/Users/zyh/history copy/`
- Xcode 项目：`/Users/zyh/history copy/ClipboardHistory/`
- 数据存储：`~/Library/Application Support/ClipboardHistory/`
