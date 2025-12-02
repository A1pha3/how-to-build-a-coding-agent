# AI 编程助手工作坊 - 中文文档

欢迎来到 AI 编程助手工作坊的中文文档！本项目是一个循序渐进的学习项目，通过 Go 语言实现与 Anthropic Claude API 的集成，并逐步添加文件读取、命令执行、代码搜索等工具能力。

> **📝 文档状态**：文档系统正在逐步完善中。本索引列出了所有计划的文档，部分文档可能尚未完成。我们正在按照工作坊的步骤顺序逐步添加内容。

## 📚 文档导航

### 🚀 入门指南

从这里开始，快速了解项目并搭建开发环境。

- [项目概览](getting-started/overview.md) - 了解项目目标、技术栈和学习收益
- [前置要求](getting-started/prerequisites.md) - 查看所需的软件依赖和版本要求
- [安装配置](getting-started/installation.md) - 详细的环境搭建步骤
- [快速开始](getting-started/quick-start.md) - 运行你的第一个 AI Agent

### 🏗️ 架构设计

深入理解系统的设计原理和各组件的职责。

- [架构概览](architecture/overview.md) - 系统整体架构和设计理念
- [Agent 设计](architecture/agent-design.md) - Agent 的核心设计模式和会话管理
- [工具系统](architecture/tool-system.md) - 工具的定义、注册和执行流程
- [事件循环](architecture/event-loop.md) - 事件循环的工作机制和流程

### 🎓 工作坊教程

跟随分步教程，从基础聊天到完整 Agent 的构建过程。

- [步骤 1：基础聊天](workshop/step-1-chat.md) - 实现与 Claude API 的基本对话
- [步骤 2：文件读取](workshop/step-2-read.md) - 添加文件读取工具
- [步骤 3：文件列表](workshop/step-3-list.md) - 实现文件系统遍历
- [步骤 4：命令执行](workshop/step-4-bash.md) - 集成 Shell 命令执行
- [步骤 5：文件编辑](workshop/step-5-edit.md) - 实现文件编辑功能
- [步骤 6：代码搜索](workshop/step-6-search.md) - 集成 ripgrep 代码搜索

### 📖 API 参考

查阅详细的 API 文档和函数签名。

- [Agent API](api-reference/agent.md) - Agent 结构体和核心方法
- [工具 API](api-reference/tools.md) - 所有内置工具的接口说明
- [类型定义](api-reference/types.md) - 核心数据结构和类型

### 📝 开发指南

学习如何扩展和定制你的 AI Agent。

- [创建自定义工具](guides/creating-tools.md) - 工具开发完整流程和最佳实践
- [错误处理](guides/error-handling.md) - 错误处理的最佳实践
- [最佳实践](guides/best-practices.md) - 代码组织和设计模式

### 🔧 故障排查

遇到问题？这里有解决方案。

- [常见问题](troubleshooting/common-issues.md) - API 错误、环境问题的解决方法
- [调试技巧](troubleshooting/debugging.md) - 使用 verbose 模式和日志调试

## 🎯 学习路径

### 初学者路径

如果你是第一次接触本项目，建议按以下顺序学习：

1. **了解项目** → [项目概览](getting-started/overview.md)
2. **搭建环境** → [前置要求](getting-started/prerequisites.md) → [安装配置](getting-started/installation.md)
3. **快速体验** → [快速开始](getting-started/quick-start.md)
4. **理解架构** → [架构概览](architecture/overview.md)
5. **动手实践** → 按顺序完成[工作坊教程](workshop/)

### 进阶开发者路径

如果你已经熟悉基础概念，想要深入了解或扩展功能：

1. **深入架构** → [Agent 设计](architecture/agent-design.md) → [工具系统](architecture/tool-system.md) → [事件循环](architecture/event-loop.md)
2. **API 参考** → [Agent API](api-reference/agent.md) → [工具 API](api-reference/tools.md) → [类型定义](api-reference/types.md)
3. **扩展开发** → [创建自定义工具](guides/creating-tools.md) → [最佳实践](guides/best-practices.md)

### 问题解决路径

遇到问题需要快速解决：

1. **查看常见问题** → [常见问题](troubleshooting/common-issues.md)
2. **学习调试** → [调试技巧](troubleshooting/debugging.md)
3. **理解错误处理** → [错误处理](guides/error-handling.md)

## 📋 文档分类索引

### 按难度分类

#### 入门级 (Beginner)
- 项目概览
- 前置要求
- 安装配置
- 快速开始
- 常见问题

#### 中级 (Intermediate)
- 架构概览
- 工作坊教程（步骤 1-6）
- 工具 API
- 创建自定义工具
- 调试技巧

#### 高级 (Advanced)
- Agent 设计
- 工具系统
- 事件循环
- Agent API
- 类型定义
- 最佳实践
- 错误处理

### 按主题分类

#### 环境搭建
- 前置要求
- 安装配置
- 常见问题（环境相关）

#### 核心概念
- 项目概览
- 架构概览
- Agent 设计
- 工具系统
- 事件循环

#### 实践教程
- 快速开始
- 工作坊教程（步骤 1-6）

#### 开发扩展
- 创建自定义工具
- API 参考
- 最佳实践

#### 问题解决
- 错误处理
- 调试技巧
- 常见问题

## 🤝 贡献指南

文档持续更新中，如果你发现任何问题或有改进建议，欢迎：

- 提交 Issue 报告问题
- 提交 Pull Request 改进文档
- 分享你的使用经验和最佳实践

## 📄 许可证

本项目文档遵循与项目相同的许可证。

---

**提示**：文档中的所有代码示例都经过测试，可以直接运行。如果遇到问题，请查看[故障排查](troubleshooting/)部分。
