# 步骤 2：文件读取

## 学习目标

- 理解工具系统的基本概念和架构
- 学习如何定义和注册工具
- 掌握 JSON Schema 的自动生成机制
- 了解工具调用的完整流程
- 理解工具执行循环的工作原理

## 背景知识

在步骤 1 中，我们构建了一个基本的聊天程序。但 Claude 只能进行对话，无法与外部世界交互。在这一步中，我们将引入**工具系统**（Tool System），让 Claude 能够读取文件内容。

### 什么是工具？

工具是赋予 AI 能力的函数。通过工具，Claude 可以：
- 读取文件
- 执行命令
- 搜索代码
- 调用 API
- 操作数据库

工具系统的核心思想是：
1. **声明**：告诉 Claude 有哪些工具可用
2. **决策**：Claude 决定何时使用哪个工具
3. **执行**：我们的代码执行工具并返回结果
4. **响应**：Claude 根据工具结果生成最终回复

### 工具调用流程

```
用户输入 → Claude 分析 → 决定使用工具 → 我们执行工具 → 返回结果 → Claude 处理结果 → 生成回复
```

这个流程可能会重复多次，直到 Claude 不再需要使用工具。

## 实现步骤

### 1. 新增的导入

```go
import (
	// ... 之前的导入 ...
	"encoding/json"
	"github.com/invopop/jsonschema"
)
```

- `encoding/json`：用于解析工具输入参数
- `jsonschema`：用于自动生成 JSON Schema

### 2. 工具定义结构

```go
type ToolDefinition struct {
	Name        string                         `json:"name"`
	Description string                         `json:"description"`
	InputSchema anthropic.ToolInputSchemaParam `json:"input_schema"`
	Function    func(input json.RawMessage) (string, error)
}
```

**字段说明**：
- `Name`：工具的唯一标识符（如 "read_file"）
- `Description`：工具的功能描述，Claude 会根据这个决定是否使用
- `InputSchema`：工具的输入参数 Schema（JSON Schema 格式）
- `Function`：实际执行工具的 Go 函数

### 3. ReadFile 工具定义

```go
var ReadFileDefinition = ToolDefinition{
	Name:        "read_file",
	Description: "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names.",
	InputSchema: ReadFileInputSchema,
	Function:    ReadFile,
}
```

**Description 的重要性**：这个描述会发送给 Claude，它会根据描述决定何时使用这个工具。好的描述应该：
- 清楚说明工具的功能
- 说明适用场景
- 指出限制和注意事项

### 4. 输入参数定义

```go
type ReadFileInput struct {
	Path string `json:"path" jsonschema_description:"The relative path of a file in the working directory."`
}

var ReadFileInputSchema = GenerateSchema[ReadFileInput]()
```

**关键点**：
- 使用 struct 定义输入参数
- `json` tag 指定 JSON 字段名
- `jsonschema_description` tag 提供字段描述
- `GenerateSchema` 函数自动生成 JSON Schema

### 5. Schema 生成函数

```go
func GenerateSchema[T any]() anthropic.ToolInputSchemaParam {
	reflector := jsonschema.Reflector{
		AllowAdditionalProperties: false,
		DoNotReference:            true,
	}
	var v T

	schema := reflector.Reflect(v)

	return anthropic.ToolInputSchemaParam{
		Properties: schema.Properties,
	}
}
```

**这是一个泛型函数**，可以为任何类型生成 Schema：
- `AllowAdditionalProperties: false`：不允许额外的字段
- `DoNotReference: true`：生成内联 Schema，不使用引用
- 使用反射自动提取结构体信息


### 6. ReadFile 工具实现

```go
func ReadFile(input json.RawMessage) (string, error) {
	readFileInput := ReadFileInput{}
	err := json.Unmarshal(input, &readFileInput)
	if err != nil {
		panic(err)
	}

	log.Printf("Reading file: %s", readFileInput.Path)
	content, err := os.ReadFile(readFileInput.Path)
	if err != nil {
		log.Printf("Failed to read file %s: %v", readFileInput.Path, err)
		return "", err
	}
	log.Printf("Successfully read file %s (%d bytes)", readFileInput.Path, len(content))
	return string(content), nil
}
```

**实现要点**：
1. 接收 `json.RawMessage` 类型的输入
2. 反序列化为具体的输入结构体
3. 执行实际操作（读取文件）
4. 返回结果字符串和可能的错误
5. 添加日志记录便于调试

### 7. Agent 结构体更新

```go
type Agent struct {
	client         *anthropic.Client
	getUserMessage func() (string, bool)
	tools          []ToolDefinition  // 新增：工具列表
	verbose        bool
}

func NewAgent(
	client *anthropic.Client,
	getUserMessage func() (string, bool),
	tools []ToolDefinition,  // 新增参数
	verbose bool,
) *Agent {
	return &Agent{
		client:         client,
		getUserMessage: getUserMessage,
		tools:          tools,
		verbose:        verbose,
	}
}
```

现在 Agent 需要知道有哪些工具可用。

### 8. 主函数更新

```go
func main() {
	// ... 之前的代码 ...

	tools := []ToolDefinition{ReadFileDefinition}
	if *verbose {
		log.Printf("Initialized %d tools", len(tools))
	}
	agent := NewAgent(&client, getUserMessage, tools, *verbose)
	err := agent.Run(context.TODO())
	if err != nil {
		fmt.Printf("Error: %s\n", err.Error())
	}
}
```

创建工具列表并传递给 Agent。

### 9. runInference 函数更新

```go
func (a *Agent) runInference(ctx context.Context, conversation []anthropic.MessageParam) (*anthropic.Message, error) {
	// 将我们的工具定义转换为 Anthropic API 格式
	anthropicTools := []anthropic.ToolUnionParam{}
	for _, tool := range a.tools {
		anthropicTools = append(anthropicTools, anthropic.ToolUnionParam{
			OfTool: &anthropic.ToolParam{
				Name:        tool.Name,
				Description: anthropic.String(tool.Description),
				InputSchema: tool.InputSchema,
			},
		})
	}

	if a.verbose {
		log.Printf("Making API call to Claude with model: %s and %d tools", 
			anthropic.ModelClaude3_7SonnetLatest, len(anthropicTools))
	}

	message, err := a.client.Messages.New(ctx, anthropic.MessageNewParams{
		Model:     anthropic.ModelClaude3_7SonnetLatest,
		MaxTokens: int64(1024),
		Messages:  conversation,
		Tools:     anthropicTools,  // 新增：传递工具定义
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

**关键变化**：
- 构建 `anthropicTools` 列表
- 在 API 调用中添加 `Tools` 参数
- Claude 现在知道可以使用这些工具

### 10. Run 函数的工具处理循环

这是最复杂的部分。我们需要处理 Claude 的工具调用请求：

```go
func (a *Agent) Run(ctx context.Context) error {
	conversation := []anthropic.MessageParam{}

	if a.verbose {
		log.Println("Starting chat session with tools enabled")
	}
	fmt.Println("Chat with Claude (use 'ctrl-c' to quit)")

	for {
		// ... 获取用户输入的代码（与步骤1相同）...

		message, err := a.runInference(ctx, conversation)
		if err != nil {
			if a.verbose {
				log.Printf("Error during inference: %v", err)
			}
			return err
		}
		conversation = append(conversation, message.ToParam())

		// 新增：工具处理循环
		for {
			var toolResults []anthropic.ContentBlockParamUnion
			var hasToolUse bool

			if a.verbose {
				log.Printf("Processing %d content blocks from Claude", len(message.Content))
			}

			// 处理响应中的每个内容块
			for _, content := range message.Content {
				switch content.Type {
				case "text":
					fmt.Printf("\u001b[93mClaude\u001b[0m: %s\n", content.Text)
				case "tool_use":
					hasToolUse = true
					toolUse := content.AsToolUse()
					if a.verbose {
						log.Printf("Tool use detected: %s with input: %s", 
							toolUse.Name, string(toolUse.Input))
					}
					fmt.Printf("\u001b[96mtool\u001b[0m: %s(%s)\n", 
						toolUse.Name, string(toolUse.Input))

					// 执行工具
					var toolResult string
					var toolError error
					var toolFound bool
					for _, tool := range a.tools {
						if tool.Name == toolUse.Name {
							if a.verbose {
								log.Printf("Executing tool: %s", tool.Name)
							}
							toolResult, toolError = tool.Function(toolUse.Input)
							fmt.Printf("\u001b[92mresult\u001b[0m: %s\n", toolResult)
							if toolError != nil {
								fmt.Printf("\u001b[91merror\u001b[0m: %s\n", toolError.Error())
							}
							if a.verbose {
								if toolError != nil {
									log.Printf("Tool execution failed: %v", toolError)
								} else {
									log.Printf("Tool execution successful, result length: %d chars", 
										len(toolResult))
								}
							}
							toolFound = true
							break
						}
					}

					if !toolFound {
						toolError = fmt.Errorf("tool '%s' not found", toolUse.Name)
						fmt.Printf("\u001b[91merror\u001b[0m: %s\n", toolError.Error())
					}

					// 构建工具结果
					if toolError != nil {
						toolResults = append(toolResults, 
							anthropic.NewToolResultBlock(toolUse.ID, toolError.Error(), true))
					} else {
						toolResults = append(toolResults, 
							anthropic.NewToolResultBlock(toolUse.ID, toolResult, false))
					}
				}
			}

			// 如果没有工具调用，退出内层循环
			if !hasToolUse {
				break
			}

			// 将工具结果发送回 Claude
			if a.verbose {
				log.Printf("Sending %d tool results back to Claude", len(toolResults))
			}
			toolResultMessage := anthropic.NewUserMessage(toolResults...)
			conversation = append(conversation, toolResultMessage)

			// 获取 Claude 处理工具结果后的响应
			message, err = a.runInference(ctx, conversation)
			if err != nil {
				if a.verbose {
					log.Printf("Error during followup inference: %v", err)
				}
				return err
			}
			conversation = append(conversation, message.ToParam())

			if a.verbose {
				log.Printf("Received followup response with %d content blocks", 
					len(message.Content))
			}

			// 继续循环，处理新的响应
		}
	}

	if a.verbose {
		log.Println("Chat session ended")
	}
	return nil
}
```


## 运行和测试

### 编译和运行

```bash
# 基本运行
go run read.go

# 启用详细日志
go run read.go --verbose
```

### 示例对话

```
Chat with Claude (use 'ctrl-c' to quit)
You: 请读取 README.md 文件的内容
tool: read_file({"path":"README.md"})
result: # AI Programming Assistant Workshop
...
Claude: 我已经读取了 README.md 文件。这是一个 AI 编程助手工作坊项目...

You: go.mod 文件里有什么依赖？
tool: read_file({"path":"go.mod"})
result: module github.com/example/workshop
...
Claude: 根据 go.mod 文件，这个项目主要依赖：
1. github.com/anthropics/anthropic-sdk-go - Anthropic 官方 SDK
2. github.com/invopop/jsonschema - JSON Schema 生成库
```

### 工具调用流程演示

使用 verbose 模式可以看到完整的工具调用流程：

```bash
$ go run read.go --verbose
```

你会看到：
1. 用户输入被发送到 Claude
2. Claude 决定使用 `read_file` 工具
3. 我们执行工具并返回结果
4. 结果被发送回 Claude
5. Claude 基于文件内容生成最终回复

## 代码解析

### 核心概念

#### 1. 工具调用是异步的

Claude 的响应可能包含多种内容类型：
- `text`：普通文本回复
- `tool_use`：工具调用请求

我们需要检查每个内容块的类型并相应处理。

#### 2. 工具执行循环

```
Claude 响应 → 检查是否有工具调用 → 执行工具 → 发送结果 → 获取新响应 → 重复
```

这个循环会持续到 Claude 不再请求工具调用为止。

#### 3. 工具结果格式

```go
anthropic.NewToolResultBlock(toolUse.ID, result, isError)
```

- `toolUse.ID`：工具调用的唯一标识符（由 Claude 生成）
- `result`：工具执行结果（字符串）
- `isError`：是否是错误结果

### 关键代码段分析

#### Schema 自动生成

```go
type ReadFileInput struct {
	Path string `json:"path" jsonschema_description:"The relative path of a file in the working directory."`
}

var ReadFileInputSchema = GenerateSchema[ReadFileInput]()
```

这段代码的魔力在于：
1. 定义一个普通的 Go 结构体
2. 使用 struct tags 添加描述
3. `GenerateSchema` 自动生成 JSON Schema
4. 无需手动编写 Schema JSON

生成的 Schema 大致如下：
```json
{
  "type": "object",
  "properties": {
    "path": {
      "type": "string",
      "description": "The relative path of a file in the working directory."
    }
  },
  "required": ["path"]
}
```

#### 工具查找和执行

```go
for _, tool := range a.tools {
	if tool.Name == toolUse.Name {
		toolResult, toolError = tool.Function(toolUse.Input)
		toolFound = true
		break
	}
}
```

这是一个简单的线性查找。在工具数量较多时，可以考虑使用 map 优化。

#### 内容类型处理

```go
switch content.Type {
case "text":
	// 显示文本
case "tool_use":
	// 执行工具
}
```

这个 switch 语句是扩展性的关键。未来添加新的内容类型（如图片）时，只需添加新的 case。

### 为什么这样设计？

**问：为什么工具执行需要一个循环？**
答：Claude 可能需要多次使用工具。例如，它可能先读取一个文件，然后根据内容决定读取另一个文件。

**问：为什么工具函数返回 `(string, error)` 而不是其他类型？**
答：Claude API 期望工具结果是字符串。如果你的工具返回结构化数据，需要序列化为 JSON 字符串。

**问：为什么使用 `json.RawMessage` 作为输入？**
答：这样可以延迟解析。我们先接收原始 JSON，然后根据具体工具的需求解析为对应的结构体。

**问：工具执行失败时会发生什么？**
答：错误会被发送回 Claude，它会根据错误信息调整策略或告知用户。

## 练习建议

1. **添加文件存在性检查**：在读取文件前，先检查文件是否存在，提供更友好的错误信息

2. **限制文件大小**：添加文件大小检查，避免读取过大的文件：
   ```go
   info, err := os.Stat(readFileInput.Path)
   if err == nil && info.Size() > 1024*1024 { // 1MB
       return "", fmt.Errorf("file too large")
   }
   ```

3. **添加文件类型过滤**：只允许读取特定类型的文件（如 .txt, .md, .go）

4. **实现文件写入工具**：创建一个 `write_file` 工具，让 Claude 能够创建或修改文件

5. **添加工具使用统计**：记录每个工具被调用的次数

6. **实现工具超时**：为工具执行添加超时机制，避免长时间阻塞

## 常见问题

### Q: Claude 什么时候会使用工具？

A: Claude 会根据：
- 用户的请求
- 工具的描述
- 当前对话上下文

自主决定是否使用工具。你无法强制它使用或不使用某个工具。

### Q: 如何让 Claude 更倾向于使用工具？

A: 
- 编写清晰、详细的工具描述
- 在用户提示中明确提到需要的操作
- 提供使用示例

### Q: 工具可以返回二进制数据吗？

A: 不能直接返回。工具结果必须是字符串。对于二进制数据，可以：
- 返回 Base64 编码
- 返回文件路径
- 返回数据的描述

### Q: 一次可以调用多个工具吗？

A: 可以。Claude 的一个响应可能包含多个 `tool_use` 块。我们的代码会收集所有工具调用，执行它们，然后一次性返回所有结果。

### Q: 工具执行顺序重要吗？

A: 在当前实现中，工具按照 Claude 响应中的顺序执行。如果工具之间有依赖关系，需要特别注意。

### Q: 如何调试工具调用问题？

A: 
1. 使用 `--verbose` 标志查看详细日志
2. 打印 `toolUse.Input` 查看 Claude 传递的参数
3. 检查工具的 Description 是否清晰
4. 验证 Schema 定义是否正确

## 下一步

太棒了！现在 Claude 可以读取文件了。

在[步骤 3：文件列表](step-3-list.md)中，我们将添加第二个工具 `list_files`，让 Claude 能够浏览目录结构。这将展示如何管理多个工具，以及工具之间如何协同工作。

关键概念预告：
- 多工具管理
- 可选参数处理
- 文件系统遍历
- 工具组合使用
