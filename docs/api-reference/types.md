# 类型定义参考

## 概述

本文档详细说明了项目中使用的核心类型定义。这些类型构成了 Agent、工具系统和 API 交互的基础。

## 核心类型

### ToolDefinition

工具定义结构，描述一个可被 Agent 使用的工具。

```go
type ToolDefinition struct {
    Name        string
    Description string
    InputSchema anthropic.ToolInputSchemaParam
    Function    func(input json.RawMessage) (string, error)
}
```

**字段说明：**

- `Name` (string): 工具的唯一标识符
  - 用于 Claude 调用工具时指定工具名称
  - 应使用小写字母和下划线，如 `read_file`
  
- `Description` (string): 工具功能的自然语言描述
  - 帮助 Claude 理解工具的用途和使用场景
  - 应清晰说明工具的功能、输入要求和使用限制
  
- `InputSchema` (anthropic.ToolInputSchemaParam): 输入参数的 JSON Schema
  - 定义工具接受的参数结构
  - 通过 `GenerateSchema` 函数从 Go 结构体自动生成
  
- `Function` (func): 工具的执行函数
  - 接收 JSON 格式的输入参数
  - 返回字符串结果和可能的错误
  - 签名: `func(input json.RawMessage) (string, error)`

**使用示例：**

```go
var ReadFileDefinition = ToolDefinition{
    Name:        "read_file",
    Description: "Read the contents of a given relative file path.",
    InputSchema: ReadFileInputSchema,
    Function:    ReadFile,
}
```

---

### Agent

Agent 结构体，管理与 Claude API 的交互和工具执行。

```go
type Agent struct {
    client         *anthropic.Client
    getUserMessage func() (string, bool)
    tools          []ToolDefinition
    verbose        bool
}
```

**字段说明：**

- `client` (*anthropic.Client): Anthropic API 客户端
  - 用于发送请求到 Claude API
  - 通过 `anthropic.NewClient()` 创建
  
- `getUserMessage` (func() (string, bool)): 用户输入获取函数
  - 返回用户输入的文本和是否成功的标志
  - 当返回 `false` 时，Agent 结束运行
  
- `tools` ([]ToolDefinition): 可用工具列表
  - Agent 会将这些工具提供给 Claude
  - 可以为空切片表示无工具模式
  
- `verbose` (bool): 详细日志标志
  - `true`: 输出详细的调试信息
  - `false`: 仅输出必要信息

**创建示例：**

```go
agent := NewAgent(&client, getUserMessage, tools, true)
```

---

## 工具输入类型

### ReadFileInput

`read_file` 工具的输入参数。

```go
type ReadFileInput struct {
    Path string `json:"path" jsonschema_description:"The relative path of a file in the working directory."`
}
```

**字段说明：**

- `Path` (string, 必需): 要读取的文件的相对路径

**JSON 示例：**

```json
{
  "path": "README.md"
}
```

---

### ListFilesInput

`list_files` 工具的输入参数。

```go
type ListFilesInput struct {
    Path string `json:"path,omitempty" jsonschema_description:"Optional relative path to list files from. Defaults to current directory if not provided."`
}
```

**字段说明：**

- `Path` (string, 可选): 要列出的目录路径，默认为当前目录

**JSON 示例：**

```json
{
  "path": "docs"
}
```

或省略参数使用默认值：

```json
{}
```

---

### BashInput

`bash` 工具的输入参数。

```go
type BashInput struct {
    Command string `json:"command" jsonschema_description:"The bash command to execute."`
}
```

**字段说明：**

- `Command` (string, 必需): 要执行的 bash 命令

**JSON 示例：**

```json
{
  "command": "ls -la"
}
```

---

### EditFileInput

`edit_file` 工具的输入参数。

```go
type EditFileInput struct {
    Path   string `json:"path" jsonschema_description:"The path to the file"`
    OldStr string `json:"old_str" jsonschema_description:"Text to search for - must match exactly and must only have one match exactly"`
    NewStr string `json:"new_str" jsonschema_description:"Text to replace old_str with"`
}
```

**字段说明：**

- `Path` (string, 必需): 文件路径
- `OldStr` (string, 必需): 要替换的原始文本
  - 必须在文件中精确匹配
  - 必须唯一（只出现一次）
  - 可以为空字符串表示追加或创建文件
- `NewStr` (string, 必需): 替换后的新文本
  - 必须与 `OldStr` 不同

**JSON 示例：**

```json
{
  "path": "config.txt",
  "old_str": "port=8080",
  "new_str": "port=3000"
}
```

---

### CodeSearchInput

`code_search` 工具的输入参数。

```go
type CodeSearchInput struct {
    Pattern       string `json:"pattern" jsonschema_description:"The search pattern or regex to look for"`
    Path          string `json:"path,omitempty" jsonschema_description:"Optional path to search in (file or directory)"`
    FileType      string `json:"file_type,omitempty" jsonschema_description:"Optional file extension to limit search to (e.g., 'go', 'js', 'py')"`
    CaseSensitive bool   `json:"case_sensitive,omitempty" jsonschema_description:"Whether the search should be case sensitive (default: false)"`
}
```

**字段说明：**

- `Pattern` (string, 必需): 搜索模式或正则表达式
- `Path` (string, 可选): 搜索路径，默认为当前目录
- `FileType` (string, 可选): 文件类型过滤，如 `"go"`, `"js"`, `"py"`
- `CaseSensitive` (bool, 可选): 是否区分大小写，默认 `false`

**JSON 示例：**

```json
{
  "pattern": "func main",
  "file_type": "go",
  "case_sensitive": true
}
```

---

## Anthropic SDK 类型

本项目使用 Anthropic Go SDK 提供的类型。以下是常用类型的说明。

### anthropic.Client

Anthropic API 客户端。

```go
client := anthropic.NewClient()
```

**环境变量：**
- `ANTHROPIC_API_KEY`: API 密钥（必需）

---

### anthropic.MessageParam

表示对话中的一条消息。

**创建用户消息：**

```go
userMessage := anthropic.NewUserMessage(
    anthropic.NewTextBlock("Hello, Claude!")
)
```

**创建带工具结果的用户消息：**

```go
toolResultMessage := anthropic.NewUserMessage(
    anthropic.NewToolResultBlock(toolUseID, result, false)
)
```

---

### anthropic.Message

Claude API 返回的消息响应。

**主要字段：**

- `Content`: 内容块数组，可能包含文本或工具调用
- `Role`: 消息角色（通常为 "assistant"）
- `StopReason`: 停止原因（如 "end_turn", "tool_use"）

**使用示例：**

```go
message, err := client.Messages.New(ctx, params)
if err != nil {
    return err
}

for _, content := range message.Content {
    switch content.Type {
    case "text":
        fmt.Println(content.Text)
    case "tool_use":
        toolUse := content.AsToolUse()
        // 处理工具调用
    }
}
```

---

### anthropic.ContentBlock

消息内容块，可以是文本或工具调用。

**类型：**

- `"text"`: 文本内容
- `"tool_use"`: 工具调用请求

**处理示例：**

```go
for _, content := range message.Content {
    switch content.Type {
    case "text":
        // 访问文本内容
        text := content.Text
        fmt.Println(text)
        
    case "tool_use":
        // 转换为工具调用
        toolUse := content.AsToolUse()
        fmt.Printf("Tool: %s\n", toolUse.Name)
        fmt.Printf("Input: %s\n", string(toolUse.Input))
    }
}
```

---

### anthropic.ToolUse

工具调用请求，包含在 ContentBlock 中。

**主要字段：**

- `ID` (string): 工具调用的唯一标识符
- `Name` (string): 要调用的工具名称
- `Input` (json.RawMessage): JSON 格式的输入参数

**使用示例：**

```go
toolUse := content.AsToolUse()

// 查找并执行工具
for _, tool := range tools {
    if tool.Name == toolUse.Name {
        result, err := tool.Function(toolUse.Input)
        // 处理结果
    }
}
```

---

### anthropic.ToolParam

工具定义参数，用于 API 请求。

```go
type ToolParam struct {
    Name        string
    Description *string
    InputSchema ToolInputSchemaParam
}
```

**转换示例：**

```go
// 从 ToolDefinition 转换为 ToolParam
anthropicTools := []anthropic.ToolUnionParam{}
for _, tool := range tools {
    anthropicTools = append(anthropicTools, anthropic.ToolUnionParam{
        OfTool: &anthropic.ToolParam{
            Name:        tool.Name,
            Description: anthropic.String(tool.Description),
            InputSchema: tool.InputSchema,
        },
    })
}
```

---

### anthropic.ToolInputSchemaParam

工具输入参数的 JSON Schema 定义。

```go
type ToolInputSchemaParam struct {
    Properties map[string]interface{}
}
```

**生成示例：**

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

---

### anthropic.MessageNewParams

创建新消息的请求参数。

**主要字段：**

- `Model`: 使用的模型名称
- `MaxTokens`: 最大生成 token 数
- `Messages`: 对话历史
- `Tools`: 可用工具列表（可选）

**使用示例：**

```go
message, err := client.Messages.New(ctx, anthropic.MessageNewParams{
    Model:     anthropic.ModelClaude3_7SonnetLatest,
    MaxTokens: int64(1024),
    Messages:  conversation,
    Tools:     anthropicTools,
})
```

---

## 类型关系图

```
┌─────────────────────────────────────────────────────────────┐
│                         Agent                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ client: *anthropic.Client                            │   │
│  │ getUserMessage: func() (string, bool)                │   │
│  │ tools: []ToolDefinition                              │   │
│  │ verbose: bool                                        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 使用
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     ToolDefinition                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Name: string                                         │   │
│  │ Description: string                                  │   │
│  │ InputSchema: anthropic.ToolInputSchemaParam          │   │
│  │ Function: func(json.RawMessage) (string, error)      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 包含
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   工具输入类型                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ReadFileInput                                        │   │
│  │ ListFilesInput                                       │   │
│  │ BashInput                                            │   │
│  │ EditFileInput                                        │   │
│  │ CodeSearchInput                                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Anthropic SDK 类型                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Client                                               │   │
│  │ MessageParam                                         │   │
│  │ Message                                              │   │
│  │ ContentBlock                                         │   │
│  │ ToolUse                                              │   │
│  │ ToolParam                                            │   │
│  │ MessageNewParams                                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## JSON Schema 标签

工具输入类型使用特殊的结构体标签来生成 JSON Schema。

### 标签说明

**`json` 标签：**
- 定义 JSON 字段名称
- `omitempty`: 字段为空时省略

**`jsonschema_description` 标签：**
- 提供字段的描述信息
- 帮助 Claude 理解参数用途

### 使用示例

```go
type MyToolInput struct {
    // 必需字段
    Name string `json:"name" jsonschema_description:"The name of the item"`
    
    // 可选字段
    Count int `json:"count,omitempty" jsonschema_description:"Optional count, defaults to 1"`
    
    // 布尔字段
    Enabled bool `json:"enabled,omitempty" jsonschema_description:"Whether the feature is enabled"`
}
```

### 生成的 Schema

上述结构体会生成如下 JSON Schema：

```json
{
  "properties": {
    "name": {
      "type": "string",
      "description": "The name of the item"
    },
    "count": {
      "type": "integer",
      "description": "Optional count, defaults to 1"
    },
    "enabled": {
      "type": "boolean",
      "description": "Whether the feature is enabled"
    }
  },
  "required": ["name"]
}
```

## 类型转换

### JSON 到 Go 结构体

```go
func MyTool(input json.RawMessage) (string, error) {
    var myInput MyToolInput
    err := json.Unmarshal(input, &myInput)
    if err != nil {
        return "", err
    }
    
    // 使用 myInput
    return result, nil
}
```

### Go 结构体到 JSON

```go
result := MyResult{
    Status: "success",
    Count:  42,
}

jsonBytes, err := json.Marshal(result)
if err != nil {
    return "", err
}

return string(jsonBytes), nil
```

## 类型安全最佳实践

### 1. 使用强类型输入

```go
// 好的做法：定义专用输入类型
type ReadFileInput struct {
    Path string `json:"path"`
}

func ReadFile(input json.RawMessage) (string, error) {
    var params ReadFileInput
    json.Unmarshal(input, &params)
    // 类型安全的访问
    return os.ReadFile(params.Path)
}
```

```go
// 不好的做法：使用 map
func ReadFile(input json.RawMessage) (string, error) {
    var params map[string]interface{}
    json.Unmarshal(input, &params)
    // 需要类型断言，容易出错
    path := params["path"].(string)
    return os.ReadFile(path)
}
```

### 2. 验证输入参数

```go
func EditFile(input json.RawMessage) (string, error) {
    var params EditFileInput
    err := json.Unmarshal(input, &params)
    if err != nil {
        return "", err
    }
    
    // 验证必需参数
    if params.Path == "" {
        return "", fmt.Errorf("path is required")
    }
    
    // 验证业务逻辑
    if params.OldStr == params.NewStr {
        return "", fmt.Errorf("old_str and new_str must be different")
    }
    
    // 执行操作
    return editFileImpl(params)
}
```

### 3. 使用描述性的字段名

```go
// 好的做法：清晰的字段名
type CodeSearchInput struct {
    Pattern       string `json:"pattern"`
    Path          string `json:"path,omitempty"`
    FileType      string `json:"file_type,omitempty"`
    CaseSensitive bool   `json:"case_sensitive,omitempty"`
}
```

```go
// 不好的做法：模糊的字段名
type CodeSearchInput struct {
    P  string `json:"p"`
    D  string `json:"d,omitempty"`
    T  string `json:"t,omitempty"`
    CS bool   `json:"cs,omitempty"`
}
```

### 4. 提供详细的描述

```go
type MyToolInput struct {
    Path string `json:"path" jsonschema_description:"The relative path of the file to process. Must be within the working directory."`
    
    Mode string `json:"mode,omitempty" jsonschema_description:"Processing mode: 'read' (default), 'write', or 'append'"`
}
```

## 常见模式

### 可选参数模式

```go
type ToolInput struct {
    Required string `json:"required"`
    Optional string `json:"optional,omitempty"`
}

func Tool(input json.RawMessage) (string, error) {
    var params ToolInput
    json.Unmarshal(input, &params)
    
    // 使用默认值
    if params.Optional == "" {
        params.Optional = "default_value"
    }
    
    return process(params)
}
```

### 枚举值模式

```go
type ToolInput struct {
    Mode string `json:"mode" jsonschema_description:"Mode: 'fast', 'normal', or 'thorough'"`
}

func Tool(input json.RawMessage) (string, error) {
    var params ToolInput
    json.Unmarshal(input, &params)
    
    // 验证枚举值
    validModes := map[string]bool{
        "fast":     true,
        "normal":   true,
        "thorough": true,
    }
    
    if !validModes[params.Mode] {
        return "", fmt.Errorf("invalid mode: %s", params.Mode)
    }
    
    return process(params)
}
```

### 数组参数模式

```go
type ToolInput struct {
    Files []string `json:"files" jsonschema_description:"List of file paths to process"`
}

func Tool(input json.RawMessage) (string, error) {
    var params ToolInput
    json.Unmarshal(input, &params)
    
    if len(params.Files) == 0 {
        return "", fmt.Errorf("at least one file is required")
    }
    
    return processFiles(params.Files)
}
```

## 相关文档

- [Agent API 参考](agent.md) - 了解 Agent 类型的使用
- [工具 API 参考](tools.md) - 查看工具类型的实际应用
- [创建自定义工具](../guides/creating-tools.md) - 学习如何定义新的工具类型
- [工具系统架构](../architecture/tool-system.md) - 理解类型在系统中的作用
