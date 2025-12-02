# 快速开始

## 简介

欢迎来到快速开始指南！本文档将带你在 5 分钟内运行第一个 AI 编程助手，体验与 Claude 对话的乐趣。

## 前置条件

在开始之前，请确认：

- ✅ 已完成 [安装配置](installation.md)
- ✅ API 密钥已正确配置
- ✅ 项目依赖已下载

如果还没有完成，请先返回查看前面的文档。

## 第一步：运行基础聊天

### 启动程序

在项目根目录运行：

```bash
go run chat.go
```

**如果使用 devenv**：

```bash
# 先进入 devenv shell
devenv shell

# 然后运行
go run chat.go
```

### 预期输出

你应该看到：

```
Chat with Claude (use 'ctrl-c' to quit)
You: 
```

这表示程序已成功启动，正在等待你的输入。

### 第一次对话

让我们开始第一次对话：

**你输入**：
```
Hello!
```

**Claude 回复**：
```
Claude: Hello! How can I help you today?
```

恭喜！你已经成功与 Claude 进行了第一次对话。

## 尝试更多对话

### 示例 1：简单问答

**你**：
```
What is Go programming language?
```

**Claude**：
```
Claude: Go (also known as Golang) is a statically typed, compiled programming 
language designed at Google. It's known for its simplicity, efficiency, and 
excellent support for concurrent programming...
```

### 示例 2：代码解释

**你**：
```
Explain what a goroutine is
```

**Claude**：
```
Claude: A goroutine is a lightweight thread managed by the Go runtime. It's one 
of Go's key features for concurrent programming. Goroutines are much cheaper 
than OS threads...
```

### 示例 3：多轮对话

**你**：
```
Can you write a simple hello world in Go?
```

**Claude**：
```
Claude: Sure! Here's a simple Hello World program in Go:

package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
```

**你**：
```
How do I run it?
```

**Claude**：
```
Claude: To run this Go program, save it to a file (e.g., hello.go) and then:

1. Run directly: go run hello.go
2. Or compile first: go build hello.go, then run: ./hello
```

注意 Claude 记住了之前的对话上下文！

## 退出程序

要退出聊天，按 `Ctrl+C`：

```
You: ^C
```

程序会优雅地退出。

## 使用详细日志

想看看程序内部发生了什么？使用 `--verbose` 参数：

```bash
go run chat.go --verbose
```

### 详细日志输出

启动时：

```
2024/01/15 10:30:00 Verbose logging enabled
2024/01/15 10:30:00 Anthropic client initialized
2024/01/15 10:30:00 Starting chat session
Chat with Claude (use 'ctrl-c' to quit)
```

发送消息时：

```
You: Hello
2024/01/15 10:30:05 User input received: "Hello"
2024/01/15 10:30:05 Sending message to Claude, conversation length: 1
2024/01/15 10:30:05 Making API call to Claude with model: claude-3-7-sonnet-20250219
2024/01/15 10:30:06 API call successful, response received
2024/01/15 10:30:06 Received response from Claude with 1 content blocks
Claude: Hello! How can I help you today?
```

详细日志帮助你：
- 理解程序执行流程
- 调试 API 调用问题
- 学习事件循环机制

## 理解程序行为

### 对话历史

程序会维护完整的对话历史：

```
对话 1: 你 → Claude
对话 2: 你 → Claude（包含对话 1 的上下文）
对话 3: 你 → Claude（包含对话 1 和 2 的上下文）
...
```

这就是为什么 Claude 能记住之前说过的话。

### 空消息处理

如果你直接按回车（发送空消息），程序会跳过：

```
You: 
You: 
```

这避免了浪费 API 调用。

### 错误处理

如果 API 调用失败，你会看到错误信息：

```
Error: API call failed: authentication error
```

常见错误及解决方法见 [故障排查](../troubleshooting/common-issues.md)。

## 下一步：添加工具能力

基础聊天很有趣，但真正强大的是给 Claude 添加工具能力！

### 步骤 2：文件读取

让 Claude 能够读取文件：

```bash
go run read.go
```

**尝试**：
```
You: Read the file fizzbuzz.js
```

Claude 会读取文件内容并告诉你文件里有什么！

### 步骤 3：文件列表

让 Claude 能够浏览目录：

```bash
go run list_files.go
```

**尝试**：
```
You: List all files in this directory
```

### 步骤 4：命令执行

让 Claude 能够运行 Shell 命令：

```bash
go run bash_tool.go
```

**尝试**：
```
You: Run git status
```

### 步骤 5：文件编辑

让 Claude 能够修改文件：

```bash
go run edit_tool.go
```

**尝试**：
```
You: Create a Python hello world script
```

### 步骤 6：代码搜索

让 Claude 能够搜索代码：

```bash
go run code_search_tool.go
```

**尝试**：
```
You: Find all function definitions in Go files
```

## 学习路径建议

### 初学者路径

1. ✅ **运行 chat.go** - 理解基础对话（你已经完成了！）
2. 📖 **阅读 [步骤 1 教程](../workshop/step-1-chat.md)** - 深入理解代码
3. 🔧 **运行 read.go** - 体验工具系统
4. 📖 **阅读 [步骤 2 教程](../workshop/step-2-read.md)** - 学习工具实现
5. 🚀 **继续后续步骤** - 逐步掌握所有功能

### 快速体验路径

如果你想快速体验所有功能：

```bash
# 直接运行最完整的版本
go run code_search_tool.go

# 尝试各种命令
You: List all files
You: Read README.md
You: Search for "func main" in Go files
You: Run ls -la
```

### 深度学习路径

如果你想深入理解实现原理：

1. 📖 **阅读 [架构概览](../architecture/overview.md)**
2. 📖 **阅读 [Agent 设计](../architecture/agent-design.md)**
3. 📖 **阅读 [工具系统](../architecture/tool-system.md)**
4. 📖 **阅读 [事件循环](../architecture/event-loop.md)**
5. 💻 **按顺序学习所有工作坊步骤**

## 实用技巧

### 技巧 1：使用彩色输出

程序使用 ANSI 颜色代码：
- 🔵 **蓝色** - 你的输入
- 🟡 **黄色** - Claude 的回复

### 技巧 2：复制粘贴长文本

你可以复制粘贴多行文本：

```
You: Here is a long text...
(paste multiple lines)
...end of text
```

按回车发送。

### 技巧 3：使用管道输入

```bash
echo "Hello Claude" | go run chat.go
```

或从文件读取：

```bash
cat prompt.txt | go run chat.go
```

### 技巧 4：保存对话历史

重定向输出到文件：

```bash
go run chat.go 2>&1 | tee conversation.log
```

这会同时显示在终端和保存到文件。

### 技巧 5：测试 API 连接

快速测试 API 是否正常：

```bash
echo "Say hello" | go run chat.go
```

如果收到回复，说明 API 连接正常。

## 常见问题

### Q: 程序启动后没有反应？

**A**: 检查以下几点：

1. **API 密钥是否设置**：
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

2. **网络连接是否正常**：
   ```bash
   curl -I https://api.anthropic.com
   ```

3. **使用 verbose 模式查看详细信息**：
   ```bash
   go run chat.go --verbose
   ```

### Q: 收到 "authentication error"？

**A**: API 密钥配置有问题：

1. 检查密钥是否正确：
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

2. 重新设置密钥：
   ```bash
   export ANTHROPIC_API_KEY="your-correct-key"
   ```

3. 确认密钥在 Anthropic Console 中是激活状态

### Q: 响应很慢？

**A**: 可能的原因：

1. **网络延迟** - API 服务器在国外，可能需要几秒
2. **复杂问题** - Claude 思考复杂问题需要更多时间
3. **API 限流** - 达到速率限制

**正常响应时间**：1-5 秒

### Q: 如何停止正在运行的程序？

**A**: 按 `Ctrl+C` 即可。程序会优雅退出。

### Q: 可以同时运行多个实例吗？

**A**: 可以！每个实例都是独立的对话会话。

```bash
# 终端 1
go run chat.go

# 终端 2
go run chat.go
```

### Q: 对话历史会保存吗？

**A**: 不会。`chat.go` 只在内存中维护对话历史，程序退出后会丢失。

如果需要保存，可以：
1. 使用 `tee` 命令保存输出
2. 修改代码添加持久化功能
3. 使用更高级的版本（后续步骤）

## 故障排查

### 编译错误

```bash
# 清理并重新下载依赖
go clean -modcache
go mod tidy
go run chat.go
```

### 运行时错误

```bash
# 使用 verbose 模式查看详细错误
go run chat.go --verbose
```

### API 错误

查看 [故障排查文档](../troubleshooting/common-issues.md) 获取详细的错误代码说明。

## 下一步

现在你已经成功运行了第一个 AI 编程助手！接下来：

### 深入学习

- **[步骤 1 教程](../workshop/step-1-chat.md)** - 理解 chat.go 的实现
- **[步骤 2 教程](../workshop/step-2-read.md)** - 学习如何添加工具
- **[架构设计](../architecture/overview.md)** - 理解系统架构

### 继续实践

- 运行其他步骤的程序（read.go, list_files.go 等）
- 尝试不同的对话场景
- 使用 verbose 模式观察程序行为

### 扩展开发

- **[创建自定义工具](../guides/creating-tools.md)** - 添加你自己的工具
- **[最佳实践](../guides/best-practices.md)** - 学习开发技巧
- **[API 参考](../api-reference/)** - 查看详细的 API 文档

## 获取帮助

遇到问题？

- 📖 查看 [故障排查](../troubleshooting/common-issues.md)
- 🐛 在 GitHub 上提交 Issue
- 💬 加入社区讨论
- 📧 联系维护者

---

**恭喜你完成了快速开始！** 🎉

你已经迈出了构建 AI 编程助手的第一步。继续探索，你会发现更多有趣的功能和可能性！
