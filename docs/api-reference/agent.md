# Agent API 参考

## 概述

`Agent` 是本项目的核心组件,负责管理与 Claude API 的交互、处理用户输入、执行工具调用以及维护对话上下文。Agent 实现了一个完整的事件循环,协调用户、AI 模型和工具之间的交互。

## 类型定义

### Agent 结构体

```go
type Agent struct {
    client         *anthropic.Client
    getUserMessage func() (string, bool)
    tools          []ToolDefinition
    verbose        bool
}
```

**字段说明：**

- `client`: Anthropic API 客户端,用于与 Claude 模型通信
- `getUserMessage`: 获取用户输入的函数,返回输入文本和是否成功的布尔值
- `tools`: 可用工具的定义列表,Agent 会将这些工具提供给 Claude 使用
- `verbose`: 详细日志模式标志,启用后会输出详细的调试信息

## 构造函数

### NewAgent

创建一个新的 Agent 实例。

```go
func NewAgent(
    client *anthropic.Client,
    getUserMessage func() (string, bool),
    tools []ToolDefinition,
    verbose bool,
) *Agent
```

**参数：**

- `client`: Anthropic API 客户端指针
- `getUserMessage`: 用户输入获取函数,当无法获取输入时返回 `("", false)`
- `tools`: 工具定义列表,可以为空切片表示无工具
- `verbose`: 是否启用详细日志输出

**返回值：**

- `*Agent`: 初始化完成的 Agent 实例

**示例：**

```go
// 创建不带工具的简单 Agent
client := anthropic.NewClient()
scanner := bufio.NewScanner(os.Stdin)
getUserMessage := func() (string, bool) {
    if !scanner.Scan() {
        return "", false
    }
    return scanner.Text(), true
}

agent := NewAgent(&client, getUserMessage, []ToolDefinition{}, false)
```

```go
// 创建带工具的 Agent
tools := []ToolDefinition{
    ReadFileDefinition,
    ListFilesDefinition,
    BashDefinition,
}

agent := NewAgent(&client, getUserMessage, tools, true)
```

## 方法

### Run

启动 Agent 的主事件循环,处理用户输入和 AI 响应。

```go
func (a *Agent) Run(ctx context.Context) error
```

**参数：**

- `ctx`: 上下文对象,用于控制 API 调用的生命周期

**返回值：**

- `error`: 如果发生错误则返回错误对象,正常结束返回 `nil`

**行为说明：**

1. 初始化空的对话历史
2. 进入主循环:
   - 提示用户输入
   - 跳过空消息
   - 将用户消息添加到对话历史
   - 调用 `runInference` 获取 Claude 的响应
   - 处理响应中的文本和工具调用
3. 工具处理循环:
   - 收集所有工具调用请求
   - 执行每个工具并收集结果
   - 将工具结果发送回 Claude
   - 继续直到 Claude 不再请求工具调用
4. 当用户输入结束时退出循环

**错误处理：**

- API 调用失败时返回错误
- 工具执行失败时将错误信息返回给 Claude,但不中断循环
- 工具未找到时返回错误信息给 Claude

**示例：**

```go
agent := NewAgent(&client, getUserMessage, tools, false)
err := agent.Run(context.TODO())
if err != nil {
    fmt.Printf("Error: %s\n", err.Error())
}
```

### runInference

执行一次 Claude API 调用,获取模型响应。

```go
func (a *Agent) runInference(
    ctx context.Context,
    conversation []anthropic.MessageParam,
) (*anthropic.Message, error)
```

**参数：**

- `ctx`: 上下文对象
- `conversation`: 完整的对话历史,包含用户消息和助手消息

**返回值：**

- `*anthropic.Message`: Claude 的响应消息
- `error`: API 调用错误

**行为说明：**

1. 将 Agent 的工具定义转换为 Anthropic API 格式
2. 构造 API 请求参数:
   - 使用 `claude-3-7-sonnet-latest` 模型
   - 设置最大 token 数为 1024
   - 包含完整对话历史
   - 附加工具定义(如果有)
3. 调用 Anthropic API
4. 返回响应消息

**示例：**

```go
// 内部方法,通常不直接调用
message, err := a.runInference(ctx, conversation)
if err != nil {
    return err
}
```

## 使用流程

### 基础聊天流程

```go
package main

import (
    "bufio"
    "context"
    "fmt"
    "os"
    
    "github.com/anthropics/anthropic-sdk-go"
)

func main() {
    // 1. 创建 Anthropic 客户端
    client := anthropic.NewClient()
    
    // 2. 设置用户输入函数
    scanner := bufio.NewScanner(os.Stdin)
    getUserMessage := func() (string, bool) {
        if !scanner.Scan() {
            return "", false
        }
        return scanner.Text(), true
    }
    
    // 3. 创建 Agent
    agent := NewAgent(&client, getUserMessage, []ToolDefinition{}, false)
    
    // 4. 运行 Agent
    err := agent.Run(context.TODO())
    if err != nil {
        fmt.Printf("Error: %s\n", err.Error())
    }
}
```

### 带工具的 Agent 流程

```go
func main() {
    client := anthropic.NewClient()
    
    scanner := bufio.NewScanner(os.Stdin)
    getUserMessage := func() (string, bool) {
        if !scanner.Scan() {
            return "", false
        }
        return scanner.Text(), true
    }
    
    // 定义可用工具
    tools := []ToolDefinition{
        ReadFileDefinition,
        ListFilesDefinition,
    }
    
    // 创建带工具的 Agent
    agent := NewAgent(&client, getUserMessage, tools, true)
    
    err := agent.Run(context.TODO())
    if err != nil {
        fmt.Printf("Error: %s\n", err.Error())
    }
}
```

## 事件循环详解

Agent 的 `Run` 方法实现了一个双层循环结构:

### 外层循环：用户交互循环

```
用户输入 → 添加到对话 → 调用 API → 进入工具处理循环 → 返回外层循环
```

### 内层循环：工具处理循环

```
检查响应 → 发现工具调用 → 执行所有工具 → 发送结果 → 再次调用 API → 继续检查
```

这种设计确保:
- Claude 可以连续使用多个工具
- 工具结果会被 Claude 处理后再响应用户
- 只有当 Claude 完成所有工具调用后才返回用户输入循环

## 日志输出

当 `verbose` 模式启用时,Agent 会输出详细的日志信息:

```
2024/01/01 10:00:00 Verbose logging enabled
2024/01/01 10:00:00 Anthropic client initialized
2024/01/01 10:00:00 Initialized 3 tools
2024/01/01 10:00:00 Starting chat session with tools enabled
2024/01/01 10:00:01 User input received: "read the README file"
2024/01/01 10:00:01 Sending message to Claude, conversation length: 1
2024/01/01 10:00:01 Making API call to Claude with model: claude-3-7-sonnet-20250219 and 3 tools
2024/01/01 10:00:02 API call successful, response received
2024/01/01 10:00:02 Processing 2 content blocks from Claude
2024/01/01 10:00:02 Tool use detected: read_file with input: {"path":"README.md"}
2024/01/01 10:00:02 Executing tool: read_file
2024/01/01 10:00:02 Reading file: README.md
2024/01/01 10:00:02 Successfully read file README.md (1234 bytes)
2024/01/01 10:00:02 Tool execution successful, result length: 1234 chars
```

## 错误处理

### API 错误

```go
err := agent.Run(context.TODO())
if err != nil {
    // 处理 API 调用失败
    fmt.Printf("API Error: %s\n", err.Error())
}
```

常见 API 错误:
- 认证失败: 检查 `ANTHROPIC_API_KEY` 环境变量
- 网络错误: 检查网络连接
- 速率限制: 等待后重试

### 工具执行错误

工具执行错误不会中断 Agent 运行,而是将错误信息返回给 Claude:

```go
// 工具返回错误
toolResult, toolError := tool.Function(toolUse.Input)
if toolError != nil {
    // 错误信息会被发送给 Claude
    toolResults = append(toolResults, 
        anthropic.NewToolResultBlock(toolUse.ID, toolError.Error(), true))
}
```

Claude 会收到错误信息并可能:
- 尝试使用不同的参数重试
- 使用其他工具
- 向用户说明问题

## 最佳实践

### 1. 使用上下文控制超时

```go
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

err := agent.Run(ctx)
```

### 2. 优雅处理用户中断

```go
getUserMessage := func() (string, bool) {
    if !scanner.Scan() {
        // 用户按 Ctrl+C 或输入结束
        return "", false
    }
    return scanner.Text(), true
}
```

### 3. 合理选择工具集

```go
// 根据使用场景选择必要的工具
readOnlyTools := []ToolDefinition{ReadFileDefinition, ListFilesDefinition}
fullTools := []ToolDefinition{ReadFileDefinition, ListFilesDefinition, BashDefinition, EditFileDefinition}

// 只读场景使用只读工具
agent := NewAgent(&client, getUserMessage, readOnlyTools, false)
```

### 4. 启用详细日志进行调试

```go
// 开发和调试时启用 verbose 模式
agent := NewAgent(&client, getUserMessage, tools, true)

// 生产环境关闭 verbose 模式
agent := NewAgent(&client, getUserMessage, tools, false)
```

## 性能考虑

### Token 限制

当前实现设置 `MaxTokens: 1024`,适合:
- 简短的对话回复
- 工具调用响应
- 代码片段生成

如需更长的响应,可以修改 `runInference` 中的 `MaxTokens` 值。

### 对话历史管理

对话历史会持续增长,可能导致:
- API 调用成本增加
- 响应时间变长
- 超出上下文窗口限制

建议实现对话历史截断或摘要机制。

## 相关文档

- [工具系统架构](../architecture/tool-system.md) - 了解工具系统的设计
- [事件循环详解](../architecture/event-loop.md) - 深入理解事件循环机制
- [工具 API 参考](tools.md) - 查看所有可用工具
- [创建自定义工具](../guides/creating-tools.md) - 学习如何创建新工具
