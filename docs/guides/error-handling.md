# 错误处理指南

## 简介

良好的错误处理是构建可靠 AI Agent 的关键。本指南介绍如何在工具开发和 Agent 运行中优雅地处理各种错误情况。

学完本指南后，你将能够：
- 理解不同类型的错误及其处理方式
- 实现健壮的工具错误处理
- 处理 API 调用错误
- 编写清晰的错误信息
- 使用日志进行错误诊断

## 错误类型

在本项目中，主要有三类错误：

### 1. 工具执行错误

工具在执行过程中遇到的错误，如文件不存在、权限不足、参数无效等。

### 2. API 调用错误

与 Anthropic Claude API 交互时的错误，如网络问题、认证失败、配额超限等。

### 3. 系统错误

程序运行时的系统级错误，如内存不足、依赖缺失等。

## 工具错误处理

### 基本错误处理模式

工具函数应该返回清晰的错误信息：

```go
func MyTool(input json.RawMessage) (string, error) {
    // 1. 解析输入
    var params MyToolInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", fmt.Errorf("failed to parse input: %w", err)
    }
    
    // 2. 验证参数
    if params.Path == "" {
        return "", fmt.Errorf("path parameter is required")
    }
    
    // 3. 执行操作
    result, err := performOperation(params)
    if err != nil {
        return "", fmt.Errorf("operation failed: %w", err)
    }
    
    return result, nil
}
```

**关键点：**
- 使用 `fmt.Errorf` 创建错误
- 使用 `%w` 包装底层错误，保留错误链
- 提供清晰的错误上下文

### 参数验证错误

始终验证输入参数的有效性：

```go
func ValidateInput(params MyToolInput) error {
    if params.Path == "" {
        return fmt.Errorf("path cannot be empty")
    }
    
    if strings.Contains(params.Path, "..") {
        return fmt.Errorf("path traversal not allowed: %s", params.Path)
    }
    
    if params.Timeout < 0 {
        return fmt.Errorf("timeout must be non-negative, got: %d", params.Timeout)
    }
    
    return nil
}

func MyTool(input json.RawMessage) (string, error) {
    var params MyToolInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    // 验证参数
    if err := ValidateInput(params); err != nil {
        return "", err
    }
    
    // 继续执行...
}
```

### 文件操作错误

处理文件操作时的常见错误：

```go
func ReadFile(input json.RawMessage) (string, error) {
    var params ReadFileInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    log.Printf("Reading file: %s", params.Path)
    
    // 读取文件
    content, err := os.ReadFile(params.Path)
    if err != nil {
        // 区分不同的错误类型
        if os.IsNotExist(err) {
            log.Printf("File not found: %s", params.Path)
            return "", fmt.Errorf("file not found: %s", params.Path)
        }
        if os.IsPermission(err) {
            log.Printf("Permission denied: %s", params.Path)
            return "", fmt.Errorf("permission denied: %s", params.Path)
        }
        log.Printf("Failed to read file %s: %v", params.Path, err)
        return "", fmt.Errorf("failed to read file: %w", err)
    }
    
    log.Printf("Successfully read file %s (%d bytes)", params.Path, len(content))
    return string(content), nil
}
```

**最佳实践：**
- 使用 `os.IsNotExist()` 检查文件是否存在
- 使用 `os.IsPermission()` 检查权限问题
- 记录详细的错误日志
- 返回用户友好的错误信息

### 命令执行错误

执行外部命令时的错误处理：

```go
func Bash(input json.RawMessage) (string, error) {
    var params BashInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    log.Printf("Executing bash command: %s", params.Command)
    
    cmd := exec.Command("bash", "-c", params.Command)
    output, err := cmd.CombinedOutput()
    
    if err != nil {
        log.Printf("Bash command failed: %s, error: %v", params.Command, err)
        // 返回命令输出和错误信息，但不返回 error
        // 这样 Claude 可以看到错误信息并做出反应
        return fmt.Sprintf("Command failed with error: %s\nOutput: %s", 
            err.Error(), string(output)), nil
    }
    
    log.Printf("Bash command succeeded: %s (output: %d bytes)", 
        params.Command, len(output))
    return strings.TrimSpace(string(output)), nil
}
```

**注意：**
- 对于 bash 工具，我们返回错误信息作为结果而不是 error
- 这允许 Claude 看到错误并尝试修正命令
- 使用 `CombinedOutput()` 同时捕获 stdout 和 stderr


## API 错误处理

### API 调用错误

在 Agent 的 `runInference` 方法中处理 API 错误：

```go
func (a *Agent) runInference(ctx context.Context, conversation []anthropic.MessageParam) (*anthropic.Message, error) {
    // 准备工具定义
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
        log.Printf("Making API call to Claude with %d tools", len(anthropicTools))
    }
    
    // 调用 API
    message, err := a.client.Messages.New(ctx, anthropic.MessageNewParams{
        Model:     anthropic.ModelClaude3_7SonnetLatest,
        MaxTokens: int64(1024),
        Messages:  conversation,
        Tools:     anthropicTools,
    })
    
    if err != nil {
        log.Printf("API call failed: %v", err)
        return nil, fmt.Errorf("API call failed: %w", err)
    }
    
    if a.verbose {
        log.Printf("API call successful")
    }
    
    return message, nil
}
```

### 常见 API 错误及处理

#### 1. 认证错误

**错误信息：** `authentication_error` 或 `invalid_api_key`

**原因：**
- API 密钥未设置
- API 密钥无效或已过期

**解决方法：**
```bash
# 检查环境变量
echo $ANTHROPIC_API_KEY

# 设置 API 密钥
export ANTHROPIC_API_KEY="your-api-key-here"
```

#### 2. 配额超限错误

**错误信息：** `rate_limit_error` 或 `quota_exceeded`

**原因：**
- 请求频率过高
- 账户配额用尽

**处理策略：**
```go
func (a *Agent) runInferenceWithRetry(ctx context.Context, conversation []anthropic.MessageParam) (*anthropic.Message, error) {
    maxRetries := 3
    baseDelay := time.Second
    
    for i := 0; i < maxRetries; i++ {
        message, err := a.runInference(ctx, conversation)
        if err == nil {
            return message, nil
        }
        
        // 检查是否是速率限制错误
        if isRateLimitError(err) && i < maxRetries-1 {
            delay := baseDelay * time.Duration(1<<uint(i)) // 指数退避
            log.Printf("Rate limit hit, retrying in %v...", delay)
            time.Sleep(delay)
            continue
        }
        
        return nil, err
    }
    
    return nil, fmt.Errorf("max retries exceeded")
}

func isRateLimitError(err error) bool {
    // 检查错误类型
    return strings.Contains(err.Error(), "rate_limit") || 
           strings.Contains(err.Error(), "quota_exceeded")
}
```

#### 3. 网络错误

**错误信息：** `connection_error` 或 `timeout`

**处理策略：**
```go
func (a *Agent) runInferenceWithTimeout(ctx context.Context, conversation []anthropic.MessageParam) (*anthropic.Message, error) {
    // 创建带超时的上下文
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()
    
    message, err := a.runInference(ctx, conversation)
    if err != nil {
        if ctx.Err() == context.DeadlineExceeded {
            return nil, fmt.Errorf("API call timed out after 30 seconds")
        }
        return nil, err
    }
    
    return message, nil
}
```

#### 4. 无效请求错误

**错误信息：** `invalid_request_error`

**原因：**
- 消息格式不正确
- 参数超出限制
- 工具定义无效

**调试方法：**
```go
if a.verbose {
    // 打印请求详情
    log.Printf("Request details:")
    log.Printf("  Model: %s", anthropic.ModelClaude3_7SonnetLatest)
    log.Printf("  Messages: %d", len(conversation))
    log.Printf("  Tools: %d", len(anthropicTools))
    
    // 打印最后一条消息
    if len(conversation) > 0 {
        lastMsg := conversation[len(conversation)-1]
        log.Printf("  Last message type: %T", lastMsg)
    }
}
```

## 错误信息最佳实践

### 编写清晰的错误信息

**不好的错误信息：**
```go
return "", fmt.Errorf("error")
return "", fmt.Errorf("failed")
return "", errors.New("something went wrong")
```

**好的错误信息：**
```go
return "", fmt.Errorf("failed to read file %s: file not found", path)
return "", fmt.Errorf("invalid timeout value: expected positive integer, got %d", timeout)
return "", fmt.Errorf("command execution failed: %s (exit code: %d)", cmd, exitCode)
```

### 错误信息结构

好的错误信息应该包含：

1. **操作描述**：说明正在执行什么操作
2. **失败原因**：说明为什么失败
3. **相关上下文**：提供有助于调试的信息

```go
// 模板：failed to [操作] [对象]: [原因]
fmt.Errorf("failed to parse JSON input: unexpected token at position %d", pos)
fmt.Errorf("failed to connect to database: connection timeout after %v", timeout)
fmt.Errorf("failed to create directory %s: permission denied", dir)
```

### 错误包装

使用 `%w` 保留错误链：

```go
func processFile(path string) error {
    content, err := readFile(path)
    if err != nil {
        // 包装错误，保留原始错误
        return fmt.Errorf("failed to process file %s: %w", path, err)
    }
    
    if err := validateContent(content); err != nil {
        return fmt.Errorf("content validation failed for %s: %w", path, err)
    }
    
    return nil
}

// 调用者可以检查底层错误
err := processFile("test.txt")
if err != nil {
    if errors.Is(err, os.ErrNotExist) {
        // 处理文件不存在的情况
    }
}
```

## 日志记录

### 日志级别

本项目使用简单的日志策略：

```go
// 正常操作日志（verbose 模式）
if a.verbose {
    log.Printf("Starting operation: %s", operation)
}

// 错误日志（始终记录）
log.Printf("Operation failed: %v", err)

// 成功日志（verbose 模式）
if a.verbose {
    log.Printf("Operation completed successfully")
}
```

### 日志最佳实践

**1. 记录关键操作：**
```go
log.Printf("Reading file: %s", path)
log.Printf("Executing command: %s", cmd)
log.Printf("Making API call with %d messages", len(messages))
```

**2. 记录错误详情：**
```go
log.Printf("Failed to read file %s: %v", path, err)
log.Printf("API call failed: %v", err)
log.Printf("Tool execution failed: %s, error: %v", toolName, err)
```

**3. 记录成功结果：**
```go
log.Printf("Successfully read file %s (%d bytes)", path, len(content))
log.Printf("Command executed successfully (output: %d bytes)", len(output))
log.Printf("API call successful, received %d content blocks", len(message.Content))
```

**4. 使用结构化信息：**
```go
log.Printf("Tool execution: name=%s, input_size=%d, duration=%v", 
    toolName, len(input), duration)
```


## 错误恢复策略

### 工具级错误恢复

在 Agent 的事件循环中，工具错误会被捕获并返回给 Claude：

```go
// 在 Agent.Run 方法中
for _, content := range message.Content {
    switch content.Type {
    case "tool_use":
        toolUse := content.AsToolUse()
        
        // 执行工具
        var toolResult string
        var toolError error
        
        for _, tool := range a.tools {
            if tool.Name == toolUse.Name {
                toolResult, toolError = tool.Function(toolUse.Input)
                break
            }
        }
        
        // 将错误作为工具结果返回
        if toolError != nil {
            toolResults = append(toolResults, 
                anthropic.NewToolResultBlock(toolUse.ID, toolError.Error(), true))
        } else {
            toolResults = append(toolResults, 
                anthropic.NewToolResultBlock(toolUse.ID, toolResult, false))
        }
    }
}
```

**关键点：**
- 工具错误不会中断 Agent 运行
- 错误信息返回给 Claude，让它尝试修正
- Claude 可以根据错误信息调整策略

### 示例：Claude 如何处理错误

**场景 1：文件不存在**
```
用户: 读取 config.txt 文件
Claude: [调用 read_file 工具]
工具: 错误 - file not found: config.txt
Claude: 抱歉，config.txt 文件不存在。让我先列出当前目录的文件。
Claude: [调用 list_files 工具]
```

**场景 2：命令执行失败**
```
用户: 运行 make build
Claude: [调用 bash 工具]
工具: Command failed: make: *** No rule to make target 'build'
Claude: 看起来没有 'build' 目标。让我检查 Makefile 中有哪些可用目标。
Claude: [调用 read_file("Makefile")]
```

### 优雅降级

当某个功能不可用时，提供替代方案：

```go
func SearchCode(input json.RawMessage) (string, error) {
    var params CodeSearchInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    // 尝试使用 ripgrep
    cmd := exec.Command("rg", params.Pattern)
    output, err := cmd.Output()
    
    if err != nil {
        // 检查是否是因为 ripgrep 未安装
        if _, err := exec.LookPath("rg"); err != nil {
            log.Printf("ripgrep not found, falling back to grep")
            // 降级到 grep
            cmd = exec.Command("grep", "-r", params.Pattern, ".")
            output, err = cmd.Output()
            if err != nil {
                return "", fmt.Errorf("search failed: %w", err)
            }
        } else {
            return "", fmt.Errorf("search failed: %w", err)
        }
    }
    
    return string(output), nil
}
```

## 调试技巧

### 使用 Verbose 模式

启用详细日志输出：

```bash
go run read.go --verbose
```

Verbose 模式会输出：
- API 调用详情
- 工具执行过程
- 消息处理流程
- 错误堆栈信息

### 检查错误类型

使用 `errors.Is` 和 `errors.As` 检查特定错误：

```go
import "errors"

func handleError(err error) {
    // 检查是否是特定错误
    if errors.Is(err, os.ErrNotExist) {
        log.Println("File does not exist")
        return
    }
    
    // 提取特定错误类型
    var pathError *os.PathError
    if errors.As(err, &pathError) {
        log.Printf("Path error: op=%s, path=%s, err=%v", 
            pathError.Op, pathError.Path, pathError.Err)
        return
    }
    
    // 其他错误
    log.Printf("Unknown error: %v", err)
}
```

### 添加调试输出

在关键位置添加调试信息：

```go
func MyTool(input json.RawMessage) (string, error) {
    log.Printf("[DEBUG] MyTool called with input: %s", string(input))
    
    var params MyToolInput
    if err := json.Unmarshal(input, &params); err != nil {
        log.Printf("[DEBUG] Failed to unmarshal: %v", err)
        return "", err
    }
    
    log.Printf("[DEBUG] Parsed params: %+v", params)
    
    result, err := performOperation(params)
    if err != nil {
        log.Printf("[DEBUG] Operation failed: %v", err)
        return "", err
    }
    
    log.Printf("[DEBUG] Operation succeeded, result length: %d", len(result))
    return result, nil
}
```

### 使用 panic 和 recover

对于不应该发生的错误，使用 panic：

```go
func GenerateSchema[T any]() anthropic.ToolInputSchemaParam {
    reflector := jsonschema.Reflector{
        AllowAdditionalProperties: false,
        DoNotReference:            true,
    }
    var v T
    
    schema := reflector.Reflect(v)
    if schema == nil {
        // 这不应该发生
        panic("failed to generate schema: reflector returned nil")
    }
    
    return anthropic.ToolInputSchemaParam{
        Properties: schema.Properties,
    }
}
```

在顶层捕获 panic：

```go
func main() {
    defer func() {
        if r := recover(); r != nil {
            log.Printf("Panic recovered: %v", r)
            log.Printf("Stack trace:\n%s", debug.Stack())
            os.Exit(1)
        }
    }()
    
    // 正常程序逻辑
    // ...
}
```

## 错误处理检查清单

在实现工具时，确保：

- [ ] 所有输入参数都经过验证
- [ ] 所有错误都有清晰的错误信息
- [ ] 使用 `%w` 包装底层错误
- [ ] 记录关键操作和错误
- [ ] 区分不同类型的错误（文件不存在 vs 权限错误）
- [ ] 为用户提供可操作的错误信息
- [ ] 测试错误场景（不仅测试成功路径）
- [ ] 文档中说明可能的错误情况

## 常见错误场景及解决方案

### 场景 1：JSON 解析失败

**错误：** `invalid character 'x' looking for beginning of value`

**原因：** 输入不是有效的 JSON

**解决：**
```go
func MyTool(input json.RawMessage) (string, error) {
    var params MyToolInput
    if err := json.Unmarshal(input, &params); err != nil {
        log.Printf("Invalid JSON input: %s", string(input))
        return "", fmt.Errorf("failed to parse input JSON: %w", err)
    }
    // ...
}
```

### 场景 2：空指针引用

**错误：** `panic: runtime error: invalid memory address or nil pointer dereference`

**原因：** 访问了 nil 指针

**解决：**
```go
func ProcessData(data *MyData) error {
    if data == nil {
        return fmt.Errorf("data cannot be nil")
    }
    
    if data.Items == nil {
        data.Items = []string{} // 初始化
    }
    
    // 安全地访问数据
    // ...
}
```

### 场景 3：资源泄漏

**错误：** 文件句柄或连接未关闭

**解决：**
```go
func ReadLargeFile(path string) (string, error) {
    file, err := os.Open(path)
    if err != nil {
        return "", err
    }
    defer file.Close() // 确保文件被关闭
    
    content, err := io.ReadAll(file)
    if err != nil {
        return "", err
    }
    
    return string(content), nil
}
```

## 总结

良好的错误处理包括：

1. **预防**：验证输入，检查前置条件
2. **检测**：捕获所有可能的错误
3. **报告**：提供清晰、可操作的错误信息
4. **记录**：使用日志记录错误详情
5. **恢复**：在可能的情况下优雅降级
6. **测试**：测试错误场景，不仅测试成功路径

## 下一步

- 查看 [创建自定义工具](creating-tools.md) 了解工具开发的完整流程
- 阅读 [最佳实践](best-practices.md) 了解更多代码质量建议
- 参考 [调试技巧](../troubleshooting/debugging.md) 学习如何诊断问题
