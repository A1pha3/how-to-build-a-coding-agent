# 步骤 1：基础聊天

## 学习目标

- 理解如何使用 Anthropic Claude API 进行基本对话
- 掌握 Agent 的核心结构和事件循环机制
- 学习如何管理对话历史和上下文
- 了解命令行参数和日志系统的使用

## 背景知识

在这个第一步中，我们将构建一个最简单的 AI 聊天程序。这个程序能够：

1. 接收用户的文本输入
2. 将输入发送给 Claude API
3. 接收并显示 Claude 的回复
4. 维护完整的对话历史

这是整个工作坊的基础。后续步骤将在此基础上添加工具能力，但核心的对话循环机制保持不变。

### 核心概念

**Agent 模式**：Agent 是一个封装了 AI 交互逻辑的对象。它负责：
- 管理与 API 的连接
- 维护对话历史
- 处理用户输入和 AI 响应

**对话历史**：Claude API 是无状态的，每次调用都需要提供完整的对话历史。我们使用 `[]anthropic.MessageParam` 切片来存储所有消息。

**事件循环**：程序的主循环不断地：
1. 等待用户输入
2. 发送请求到 API
3. 显示响应
4. 重复

## 实现步骤

### 1. 项目初始化

首先，确保你已经设置好了开发环境（参见[安装配置文档](../getting-started/installation.md)）。

创建 `chat.go` 文件，这将是我们的第一个完整程序。

### 2. 导入依赖包

```go
package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/anthropics/anthropic-sdk-go"
)
```

这些包的作用：
- `bufio`：用于高效读取用户输入
- `context`：用于控制 API 调用的生命周期
- `flag`：解析命令行参数
- `fmt` 和 `log`：输出和日志记录
- `anthropic-sdk-go`：Anthropic 官方 Go SDK

### 3. 主函数和配置

```go
func main() {
	verbose := flag.Bool("verbose", false, "enable verbose logging")
	flag.Parse()

	if *verbose {
		log.SetOutput(os.Stderr)
		log.SetFlags(log.LstdFlags | log.Lshortfile)
		log.Println("Verbose logging enabled")
	} else {
		log.SetOutput(os.Stdout)
		log.SetFlags(0)
		log.SetPrefix("")
	}

	client := anthropic.NewClient()
	if *verbose {
		log.Println("Anthropic client initialized")
	}

	scanner := bufio.NewScanner(os.Stdin)
	getUserMessage := func() (string, bool) {
		if !scanner.Scan() {
			return "", false
		}
		return scanner.Text(), true
	}

	agent := NewAgent(&client, getUserMessage, *verbose)
	err := agent.Run(context.TODO())
	if err != nil {
		fmt.Printf("Error: %s\n", err.Error())
	}
}
```

**关键点**：
- `verbose` 标志控制详细日志输出，对调试非常有用
- `anthropic.NewClient()` 会自动从环境变量 `ANTHROPIC_API_KEY` 读取 API 密钥
- `getUserMessage` 是一个闭包函数，封装了读取用户输入的逻辑
- 使用 `context.TODO()` 创建一个基本的上下文（后续可以扩展为支持超时和取消）

### 4. Agent 结构体

```go
type Agent struct {
	client         *anthropic.Client
	getUserMessage func() (string, bool)
	verbose        bool
}

func NewAgent(client *anthropic.Client, getUserMessage func() (string, bool), verbose bool) *Agent {
	return &Agent{
		client:         client,
		getUserMessage: getUserMessage,
		verbose:        verbose,
	}
}
```

Agent 结构体包含：
- `client`：Anthropic API 客户端
- `getUserMessage`：获取用户输入的函数（依赖注入，便于测试）
- `verbose`：是否启用详细日志

### 5. 主事件循环

```go
func (a *Agent) Run(ctx context.Context) error {
	conversation := []anthropic.MessageParam{}

	if a.verbose {
		log.Println("Starting chat session")
	}
	fmt.Println("Chat with Claude (use 'ctrl-c' to quit)")

	for {
		fmt.Print("\u001b[94mYou\u001b[0m: ")
		userInput, ok := a.getUserMessage()
		if !ok {
			if a.verbose {
				log.Println("User input ended, breaking from chat loop")
			}
			break
		}

		// Skip empty messages
		if userInput == "" {
			if a.verbose {
				log.Println("Skipping empty message")
			}
			continue
		}

		if a.verbose {
			log.Printf("User input received: %q", userInput)
		}

		userMessage := anthropic.NewUserMessage(anthropic.NewTextBlock(userInput))
		conversation = append(conversation, userMessage)

		if a.verbose {
			log.Printf("Sending message to Claude, conversation length: %d", len(conversation))
		}

		message, err := a.runInference(ctx, conversation)
		if err != nil {
			if a.verbose {
				log.Printf("Error during inference: %v", err)
			}
			return err
		}
		conversation = append(conversation, message.ToParam())

		if a.verbose {
			log.Printf("Received response from Claude with %d content blocks", len(message.Content))
		}

		for _, content := range message.Content {
			switch content.Type {
			case "text":
				fmt.Printf("\u001b[93mClaude\u001b[0m: %s\n", content.Text)
			}
		}
	}

	if a.verbose {
		log.Println("Chat session ended")
	}
	return nil
}
```

**事件循环详解**：

1. **初始化对话历史**：`conversation := []anthropic.MessageParam{}`
2. **无限循环**：使用 `for` 循环持续处理用户输入
3. **读取输入**：调用 `getUserMessage()` 获取用户输入
4. **跳过空消息**：避免发送空白内容到 API
5. **构建消息**：使用 `anthropic.NewUserMessage()` 创建用户消息
6. **添加到历史**：将用户消息追加到对话历史
7. **调用 API**：通过 `runInference()` 发送请求
8. **保存响应**：将 Claude 的响应也添加到对话历史
9. **显示响应**：遍历响应内容并打印

**颜色编码**：
- `\u001b[94m`：蓝色（用户）
- `\u001b[93m`：黄色（Claude）
- `\u001b[0m`：重置颜色

### 6. API 调用函数

```go
func (a *Agent) runInference(ctx context.Context, conversation []anthropic.MessageParam) (*anthropic.Message, error) {
	if a.verbose {
		log.Printf("Making API call to Claude with model: %s", anthropic.ModelClaude3_7SonnetLatest)
	}

	message, err := a.client.Messages.New(ctx, anthropic.MessageNewParams{
		Model:     anthropic.ModelClaude3_7SonnetLatest,
		MaxTokens: int64(1024),
		Messages:  conversation,
	})

	if a.verbose {
		if err != nil {
			log.Printf("API call failed: %v", err)
		} else {
			log.Printf("API call successful, response received")
		}
	}

	return message, err
}
```

**API 参数说明**：
- `Model`：使用的 Claude 模型（这里使用最新的 3.7 Sonnet）
- `MaxTokens`：响应的最大 token 数量（1024 足够一般对话）
- `Messages`：完整的对话历史

## 运行和测试

### 编译和运行

```bash
# 基本运行
go run chat.go

# 启用详细日志
go run chat.go --verbose
```

### 示例对话

```
Chat with Claude (use 'ctrl-c' to quit)
You: 你好，请介绍一下你自己
Claude: 你好！我是 Claude，由 Anthropic 开发的 AI 助手。我可以帮助你完成各种任务...

You: 你能做什么？
Claude: 我可以帮助你：
1. 回答问题和提供信息
2. 进行创意写作
3. 分析和解释复杂概念
...
```

### 使用 verbose 模式调试

```bash
$ go run chat.go --verbose 2>&1 | head -20
```

你会看到详细的日志输出，包括：
- API 调用时机
- 对话历史长度
- 响应内容块数量

## 代码解析

### 核心设计思想

1. **依赖注入**：`getUserMessage` 函数作为参数传入，使得 Agent 可以在不同环境下使用（命令行、测试、Web 等）

2. **对话历史管理**：每次 API 调用都发送完整历史，这样 Claude 才能理解上下文

3. **错误处理**：API 调用失败时返回错误，由调用者决定如何处理

4. **日志分离**：verbose 日志输出到 stderr，正常输出到 stdout，便于重定向和过滤

### 关键代码段分析

#### 消息构建

```go
userMessage := anthropic.NewUserMessage(anthropic.NewTextBlock(userInput))
```

这行代码创建了一个用户消息。Claude API 支持多种内容类型（文本、图片等），这里我们只使用文本块。

#### 对话历史追加

```go
conversation = append(conversation, userMessage)
// ... API 调用 ...
conversation = append(conversation, message.ToParam())
```

关键是要同时保存用户消息和 AI 响应。`message.ToParam()` 将 API 响应转换为可以在下次请求中使用的格式。

#### 内容类型处理

```go
for _, content := range message.Content {
	switch content.Type {
	case "text":
		fmt.Printf("\u001b[93mClaude\u001b[0m: %s\n", content.Text)
	}
}
```

虽然现在只处理文本类型，但这个结构为后续添加工具调用（`tool_use` 类型）做好了准备。

### 为什么这样设计？

**问：为什么要维护完整的对话历史？**
答：Claude API 是无状态的，它不会记住之前的对话。每次调用都需要提供完整上下文。

**问：为什么使用闭包函数 `getUserMessage`？**
答：这是依赖注入的一种形式。在测试时，我们可以提供一个返回预定义输入的函数，而不需要真实的用户输入。

**问：为什么 `MaxTokens` 设置为 1024？**
答：这是一个合理的默认值。对于简单对话足够了，同时也控制了成本。实际应用中可以根据需要调整。

## 练习建议

1. **修改模型**：尝试使用不同的 Claude 模型（如 `ModelClaude3_5SonnetLatest`），观察响应的差异

2. **添加系统提示**：在 `MessageNewParams` 中添加 `System` 字段，给 Claude 设定角色：
   ```go
   System: anthropic.String("你是一个友好的编程助手，专门帮助 Go 语言开发者"),
   ```

3. **调整 MaxTokens**：尝试不同的值（如 100、500、2000），观察对响应长度的影响

4. **添加对话计数**：在循环中添加计数器，显示当前是第几轮对话

5. **保存对话历史**：将对话保存到文件，以便后续分析

6. **添加退出命令**：检测特定输入（如 "quit" 或 "exit"）来优雅退出

## 常见问题

### Q: 运行时提示 "API key not found"

A: 确保设置了环境变量：
```bash
export ANTHROPIC_API_KEY='your-api-key-here'
```

### Q: 如何查看完整的 API 请求和响应？

A: 使用 `--verbose` 标志，并查看日志输出。你也可以在代码中添加更详细的日志。

### Q: 对话历史会无限增长吗？

A: 是的，在这个简单版本中会。实际应用中需要考虑：
- Token 限制（Claude 有上下文窗口限制）
- 内存使用
- 可以实现历史截断或摘要机制

### Q: 为什么有时响应很慢？

A: 可能的原因：
- 网络延迟
- API 服务器负载
- 请求的复杂度
- 对话历史过长

### Q: 可以并发处理多个对话吗？

A: 可以。每个对话应该有自己的 Agent 实例和对话历史。Go 的 goroutine 使这变得很容易。

## 下一步

恭喜！你已经完成了第一步，构建了一个基本的 AI 聊天程序。

在[步骤 2：文件读取](step-2-read.md)（即将推出）中，我们将引入工具系统，让 Claude 能够读取文件内容。这将展示 Claude 如何从纯对话扩展到执行实际操作。

关键概念预告：
- 工具定义和注册
- 工具调用循环
- JSON Schema 生成
- 工具结果处理
