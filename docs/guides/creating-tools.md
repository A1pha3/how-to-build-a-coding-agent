# 创建自定义工具

## 简介

本指南将详细介绍如何为 AI 编程助手创建自定义工具。工具是扩展 Agent 能力的核心机制，通过工具，Claude 可以与外部系统交互、执行操作并获取信息。

学完本指南后，你将能够：
- 理解工具的结构和工作原理
- 创建自定义工具并集成到 Agent 中
- 使用 JSON Schema 定义工具的输入参数
- 实现工具的执行逻辑和错误处理

## 工具的基本结构

在本项目中，工具由 `ToolDefinition` 结构体定义：

```go
type ToolDefinition struct {
    Name        string                         // 工具名称
    Description string                         // 工具描述
    InputSchema anthropic.ToolInputSchemaParam // 输入参数的 JSON Schema
    Function    func(input json.RawMessage) (string, error) // 工具执行函数
}
```

每个工具包含四个关键部分：

1. **Name**：工具的唯一标识符，Claude 使用此名称调用工具
2. **Description**：工具功能的描述，帮助 Claude 理解何时使用该工具
3. **InputSchema**：定义工具接受的参数结构
4. **Function**：实际执行工具逻辑的函数

## 创建工具的完整流程

### 步骤 1：定义输入参数结构体

首先，定义一个结构体来描述工具的输入参数。使用 `jsonschema_description` 标签为每个字段添加描述：

```go
type MyToolInput struct {
    // 必需参数
    RequiredParam string `json:"required_param" jsonschema_description:"这是一个必需的参数"`
    
    // 可选参数（使用 omitempty 标签）
    OptionalParam string `json:"optional_param,omitempty" jsonschema_description:"这是一个可选参数"`
    
    // 布尔参数
    EnableFlag bool `json:"enable_flag,omitempty" jsonschema_description:"是否启用某个功能"`
}
```

**关键点：**
- 使用 `json` 标签指定 JSON 字段名
- 使用 `jsonschema_description` 标签提供字段描述，Claude 会根据这些描述理解参数用途
- 可选参数添加 `omitempty` 标签

### 步骤 2：生成 JSON Schema

使用 `GenerateSchema` 函数自动生成 JSON Schema：

```go
var MyToolInputSchema = GenerateSchema[MyToolInput]()
```

`GenerateSchema` 函数的实现如下：

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

这个函数使用 Go 的泛型和反射机制，从结构体自动生成符合 Anthropic API 要求的 JSON Schema。

### 步骤 3：实现工具函数

工具函数接收 `json.RawMessage` 类型的输入，返回字符串结果和可能的错误：

```go
func MyTool(input json.RawMessage) (string, error) {
    // 1. 解析输入参数
    myToolInput := MyToolInput{}
    err := json.Unmarshal(input, &myToolInput)
    if err != nil {
        return "", fmt.Errorf("failed to parse input: %w", err)
    }
    
    // 2. 验证参数
    if myToolInput.RequiredParam == "" {
        return "", fmt.Errorf("required_param cannot be empty")
    }
    
    // 3. 记录日志
    log.Printf("Executing MyTool with param: %s", myToolInput.RequiredParam)
    
    // 4. 执行工具逻辑
    result, err := performOperation(myToolInput)
    if err != nil {
        log.Printf("MyTool failed: %v", err)
        return "", err
    }
    
    // 5. 返回结果
    log.Printf("MyTool succeeded, result length: %d", len(result))
    return result, nil
}

func performOperation(input MyToolInput) (string, error) {
    // 实现具体的业务逻辑
    // ...
    return "operation result", nil
}
```

**最佳实践：**
- 始终验证输入参数
- 使用 `log.Printf` 记录关键操作
- 返回清晰的错误信息
- 将复杂逻辑分离到独立函数中

### 步骤 4：创建工具定义

将所有部分组合成 `ToolDefinition`：

```go
var MyToolDefinition = ToolDefinition{
    Name:        "my_tool",
    Description: "这个工具用于执行某个特定操作。在需要...时使用此工具。",
    InputSchema: MyToolInputSchema,
    Function:    MyTool,
}
```

**描述编写技巧：**
- 清晰说明工具的功能
- 说明何时应该使用该工具
- 提供使用场景示例
- 保持简洁但信息完整

### 步骤 5：注册工具到 Agent

在 `main` 函数中将工具添加到工具列表：

```go
func main() {
    // ... 初始化代码 ...
    
    tools := []ToolDefinition{
        ReadFileDefinition,
        ListFilesDefinition,
        MyToolDefinition,  // 添加你的工具
    }
    
    agent := NewAgent(&client, getUserMessage, tools, *verbose)
    err := agent.Run(context.TODO())
    if err != nil {
        fmt.Printf("Error: %s\n", err.Error())
    }
}
```

## 完整示例：天气查询工具

下面是一个完整的示例，展示如何创建一个查询天气的工具：

```go
// 1. 定义输入结构体
type WeatherInput struct {
    City string `json:"city" jsonschema_description:"要查询天气的城市名称"`
    Unit string `json:"unit,omitempty" jsonschema_description:"温度单位，可选值：celsius（摄氏度）或 fahrenheit（华氏度），默认为 celsius"`
}

// 2. 生成 Schema
var WeatherInputSchema = GenerateSchema[WeatherInput]()

// 3. 实现工具函数
func GetWeather(input json.RawMessage) (string, error) {
    weatherInput := WeatherInput{}
    err := json.Unmarshal(input, &weatherInput)
    if err != nil {
        return "", fmt.Errorf("failed to parse input: %w", err)
    }
    
    // 验证城市名称
    if weatherInput.City == "" {
        return "", fmt.Errorf("city name is required")
    }
    
    // 设置默认单位
    unit := weatherInput.Unit
    if unit == "" {
        unit = "celsius"
    }
    
    log.Printf("Getting weather for city: %s (unit: %s)", weatherInput.City, unit)
    
    // 模拟天气查询（实际应用中应调用天气 API）
    weather := fmt.Sprintf("Weather in %s: 22°%s, Sunny", 
        weatherInput.City, 
        map[string]string{"celsius": "C", "fahrenheit": "F"}[unit])
    
    log.Printf("Weather query successful")
    return weather, nil
}

// 4. 创建工具定义
var WeatherDefinition = ToolDefinition{
    Name:        "get_weather",
    Description: "Get current weather information for a specified city. Use this when the user asks about weather conditions.",
    InputSchema: WeatherInputSchema,
    Function:    GetWeather,
}
```

## 工具开发的高级技巧

### 处理复杂输入

对于需要嵌套结构或数组的工具：

```go
type ComplexInput struct {
    Items []string          `json:"items" jsonschema_description:"要处理的项目列表"`
    Options map[string]string `json:"options,omitempty" jsonschema_description:"可选的配置选项"`
    Config  NestedConfig     `json:"config,omitempty" jsonschema_description:"嵌套的配置对象"`
}

type NestedConfig struct {
    Timeout int  `json:"timeout" jsonschema_description:"超时时间（秒）"`
    Retry   bool `json:"retry" jsonschema_description:"是否重试"`
}
```

### 返回结构化数据

工具函数返回字符串，但可以返回 JSON 格式的结构化数据：

```go
func StructuredTool(input json.RawMessage) (string, error) {
    // ... 执行逻辑 ...
    
    result := map[string]interface{}{
        "status": "success",
        "data": []string{"item1", "item2"},
        "count": 2,
    }
    
    jsonResult, err := json.Marshal(result)
    if err != nil {
        return "", err
    }
    
    return string(jsonResult), nil
}
```

### 处理文件操作

对于涉及文件系统的工具，注意路径处理和错误检查：

```go
func FileOperationTool(input json.RawMessage) (string, error) {
    // 解析输入
    var params struct {
        Path string `json:"path"`
    }
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    // 验证路径安全性
    if strings.Contains(params.Path, "..") {
        return "", fmt.Errorf("path traversal not allowed")
    }
    
    // 检查文件是否存在
    if _, err := os.Stat(params.Path); os.IsNotExist(err) {
        return "", fmt.Errorf("file not found: %s", params.Path)
    }
    
    // 执行文件操作
    // ...
    
    return "success", nil
}
```

### 执行外部命令

使用 `exec.Command` 执行外部程序：

```go
func ExternalCommandTool(input json.RawMessage) (string, error) {
    var params struct {
        Command string   `json:"command"`
        Args    []string `json:"args,omitempty"`
    }
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    log.Printf("Executing command: %s %v", params.Command, params.Args)
    
    cmd := exec.Command(params.Command, params.Args...)
    output, err := cmd.CombinedOutput()
    
    if err != nil {
        log.Printf("Command failed: %v", err)
        return fmt.Sprintf("Command failed: %s\nOutput: %s", 
            err.Error(), string(output)), nil
    }
    
    return strings.TrimSpace(string(output)), nil
}
```

## 工具测试

### 单元测试示例

```go
func TestMyTool(t *testing.T) {
    // 准备测试输入
    input := MyToolInput{
        RequiredParam: "test_value",
        OptionalParam: "optional",
    }
    
    inputJSON, err := json.Marshal(input)
    if err != nil {
        t.Fatalf("Failed to marshal input: %v", err)
    }
    
    // 调用工具
    result, err := MyTool(inputJSON)
    
    // 验证结果
    if err != nil {
        t.Errorf("Tool execution failed: %v", err)
    }
    
    if result == "" {
        t.Error("Expected non-empty result")
    }
    
    t.Logf("Tool result: %s", result)
}
```

### 手动测试

创建一个简单的测试程序：

```go
func main() {
    // 准备测试输入
    testInput := map[string]interface{}{
        "required_param": "test",
        "optional_param": "value",
    }
    
    inputJSON, _ := json.Marshal(testInput)
    
    // 调用工具
    result, err := MyTool(inputJSON)
    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }
    
    fmt.Printf("Result: %s\n", result)
}
```

## 常见问题

### 问题 1：Claude 不使用我的工具

**可能原因：**
- 工具描述不够清晰
- 工具名称与功能不匹配
- 参数描述不明确

**解决方法：**
- 改进工具描述，明确说明使用场景
- 使用清晰、描述性的工具名称
- 为每个参数提供详细的描述

### 问题 2：工具执行失败

**调试步骤：**
1. 启用 verbose 模式：`go run mytool.go --verbose`
2. 检查日志输出，查看输入参数
3. 验证参数解析是否正确
4. 检查错误信息是否清晰

### 问题 3：Schema 生成错误

**常见问题：**
- 忘记添加 `jsonschema_description` 标签
- 结构体字段未导出（首字母小写）
- 使用了不支持的类型

**解决方法：**
- 确保所有字段首字母大写
- 为所有字段添加描述标签
- 使用基本类型或可序列化的结构体

## 最佳实践总结

1. **清晰的命名**：使用描述性的工具名称和参数名
2. **详细的描述**：为工具和参数提供充分的描述信息
3. **参数验证**：始终验证输入参数的有效性
4. **错误处理**：返回清晰、有用的错误信息
5. **日志记录**：记录关键操作和错误
6. **安全考虑**：验证文件路径、限制命令执行
7. **测试充分**：编写单元测试和集成测试
8. **文档完善**：为复杂工具编写使用文档

## 下一步

- 查看 [错误处理指南](error-handling.md)（即将推出）了解如何优雅地处理工具错误
- 阅读 [最佳实践](best-practices.md)（即将推出）了解更多代码组织和设计建议
- 参考 [API 参考文档](../api-reference/tools.md)（即将推出）查看所有内置工具的实现
