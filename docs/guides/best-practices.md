# 最佳实践

## 简介

本文档总结了开发 AI Agent 和工具时的最佳实践，涵盖代码组织、设计模式、性能优化和调试技巧。

遵循这些实践将帮助你：
- 编写清晰、可维护的代码
- 提高系统的可靠性和性能
- 简化调试和问题排查
- 构建可扩展的 Agent 系统

## 代码组织

### 项目结构

本项目采用渐进式结构，每个文件代表一个学习阶段：

```
.
├── chat.go              # 步骤1：基础聊天
├── read.go              # 步骤2：文件读取工具
├── list_files.go        # 步骤3：文件列表工具
├── bash_tool.go         # 步骤4：命令执行工具
├── edit_tool.go         # 步骤5：文件编辑工具
└── code_search_tool.go  # 步骤6：代码搜索工具
```

**优点：**
- 每个文件都是独立可运行的
- 便于学习和理解演进过程
- 可以单独测试每个阶段

### 工具定义的组织

将工具相关代码组织在一起：

```go
// 1. 输入结构体定义
type ReadFileInput struct {
    Path string `json:"path" jsonschema_description:"文件路径"`
}

// 2. Schema 生成
var ReadFileInputSchema = GenerateSchema[ReadFileInput]()

// 3. 工具函数实现
func ReadFile(input json.RawMessage) (string, error) {
    // 实现逻辑
}

// 4. 工具定义
var ReadFileDefinition = ToolDefinition{
    Name:        "read_file",
    Description: "读取文件内容",
    InputSchema: ReadFileInputSchema,
    Function:    ReadFile,
}
```

**好处：**
- 相关代码集中在一起
- 易于查找和修改
- 清晰的代码结构

### 分离关注点

将不同职责的代码分离：

```go
// Agent 核心逻辑
type Agent struct {
    client         *anthropic.Client
    getUserMessage func() (string, bool)
    tools          []ToolDefinition
    verbose        bool
}

// 工具定义（独立于 Agent）
type ToolDefinition struct {
    Name        string
    Description string
    InputSchema anthropic.ToolInputSchemaParam
    Function    func(input json.RawMessage) (string, error)
}

// 辅助函数（通用功能）
func GenerateSchema[T any]() anthropic.ToolInputSchemaParam {
    // Schema 生成逻辑
}
```

## 设计模式

### 1. 工具模式

所有工具遵循统一的接口：

```go
type ToolFunction func(input json.RawMessage) (string, error)
```

**优点：**
- 统一的工具接口
- 易于添加新工具
- 简化工具管理

**示例：**
```go
// 所有工具都遵循相同的签名
func ReadFile(input json.RawMessage) (string, error) { /* ... */ }
func ListFiles(input json.RawMessage) (string, error) { /* ... */ }
func Bash(input json.RawMessage) (string, error) { /* ... */ }
```

### 2. 依赖注入模式

通过构造函数注入依赖：

```go
func NewAgent(
    client *anthropic.Client,
    getUserMessage func() (string, bool),
    tools []ToolDefinition,
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

**优点：**
- 便于测试（可以注入 mock）
- 明确的依赖关系
- 灵活的配置

### 3. 事件循环模式

Agent 使用事件循环处理交互：

```go
func (a *Agent) Run(ctx context.Context) error {
    conversation := []anthropic.MessageParam{}
    
    for {
        // 1. 获取用户输入
        userInput, ok := a.getUserMessage()
        if !ok {
            break
        }
        
        // 2. 发送给 Claude
        message, err := a.runInference(ctx, conversation)
        if err != nil {
            return err
        }
        
        // 3. 处理工具调用
        for hasToolUse {
            // 执行工具
            // 返回结果给 Claude
            // 获取新响应
        }
    }
    
    return nil
}
```

**优点：**
- 清晰的控制流
- 支持多轮对话
- 自动处理工具调用

### 4. 泛型模式

使用 Go 泛型简化 Schema 生成：

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

// 使用
var ReadFileInputSchema = GenerateSchema[ReadFileInput]()
var ListFilesInputSchema = GenerateSchema[ListFilesInput]()
```

**优点：**
- 类型安全
- 减少重复代码
- 自动生成 Schema

## 日志记录

### 日志策略

使用两级日志：

```go
// 1. 关键操作日志（始终记录）
log.Printf("Reading file: %s", path)
log.Printf("Tool execution failed: %v", err)

// 2. 详细日志（verbose 模式）
if a.verbose {
    log.Printf("API call with %d messages", len(messages))
    log.Printf("Received %d content blocks", len(message.Content))
}
```

### 日志内容

**记录什么：**
- 工具调用和参数
- 操作结果（成功/失败）
- 错误详情
- 性能指标（可选）

**不记录什么：**
- 敏感信息（密码、密钥）
- 大量数据（完整文件内容）
- 过于频繁的操作

### 日志格式

使用结构化日志：

```go
// 好的日志
log.Printf("Tool execution: name=%s, duration=%v, success=%v", 
    toolName, duration, err == nil)

// 不好的日志
log.Printf("Tool done")
```

### 日志配置

根据运行模式配置日志：

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
    
    // ...
}
```

## 性能优化

### 1. 减少 API 调用

**批量处理工具结果：**

```go
// 好：一次返回所有工具结果
var toolResults []anthropic.ContentBlockParamUnion
for _, content := range message.Content {
    if content.Type == "tool_use" {
        result := executeToolAndGetResult(content)
        toolResults = append(toolResults, result)
    }
}
// 一次性发送所有结果
conversation = append(conversation, anthropic.NewUserMessage(toolResults...))

// 不好：每个工具结果单独发送
for _, content := range message.Content {
    if content.Type == "tool_use" {
        result := executeToolAndGetResult(content)
        conversation = append(conversation, anthropic.NewUserMessage(result))
        // 每次都调用 API
        message, _ = a.runInference(ctx, conversation)
    }
}
```

### 2. 优化文件操作

**使用缓冲 I/O：**

```go
// 读取大文件
func ReadLargeFile(path string) (string, error) {
    file, err := os.Open(path)
    if err != nil {
        return "", err
    }
    defer file.Close()
    
    // 使用缓冲读取
    reader := bufio.NewReader(file)
    var content strings.Builder
    
    buf := make([]byte, 4096)
    for {
        n, err := reader.Read(buf)
        if n > 0 {
            content.Write(buf[:n])
        }
        if err == io.EOF {
            break
        }
        if err != nil {
            return "", err
        }
    }
    
    return content.String(), nil
}
```

### 3. 限制输出大小

防止返回过大的数据：

```go
func CodeSearch(input json.RawMessage) (string, error) {
    // ... 执行搜索 ...
    
    lines := strings.Split(result, "\n")
    
    // 限制结果数量
    maxLines := 50
    if len(lines) > maxLines {
        result = strings.Join(lines[:maxLines], "\n") + 
            fmt.Sprintf("\n... (showing first %d of %d matches)", maxLines, len(lines))
    }
    
    return result, nil
}
```

### 4. 使用上下文超时

防止操作无限期阻塞：

```go
func (a *Agent) runInference(ctx context.Context, conversation []anthropic.MessageParam) (*anthropic.Message, error) {
    // 设置超时
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()
    
    message, err := a.client.Messages.New(ctx, anthropic.MessageNewParams{
        Model:     anthropic.ModelClaude3_7SonnetLatest,
        MaxTokens: int64(1024),
        Messages:  conversation,
        Tools:     anthropicTools,
    })
    
    return message, err
}
```

### 5. 避免不必要的操作

**检查前置条件：**

```go
func EditFile(input json.RawMessage) (string, error) {
    var params EditFileInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    // 快速失败：检查参数
    if params.OldStr == params.NewStr {
        return "", fmt.Errorf("old_str and new_str must be different")
    }
    
    // 只有在参数有效时才读取文件
    content, err := os.ReadFile(params.Path)
    // ...
}
```


## 调试技巧

### 1. 使用 Verbose 模式

启用详细日志查看内部运行情况：

```bash
# 运行时启用 verbose
go run read.go --verbose

# 或在代码中设置
agent := NewAgent(&client, getUserMessage, tools, true)
```

**Verbose 模式输出：**
- API 调用详情
- 工具执行过程
- 消息处理流程
- 错误堆栈

### 2. 打印中间状态

在关键位置打印状态：

```go
func (a *Agent) Run(ctx context.Context) error {
    conversation := []anthropic.MessageParam{}
    
    for {
        if a.verbose {
            log.Printf("Conversation length: %d", len(conversation))
        }
        
        userInput, ok := a.getUserMessage()
        if a.verbose {
            log.Printf("User input: %q", userInput)
        }
        
        // ...
    }
}
```

### 3. 检查工具输入

验证 Claude 发送的工具参数：

```go
func MyTool(input json.RawMessage) (string, error) {
    log.Printf("Tool input (raw): %s", string(input))
    
    var params MyToolInput
    if err := json.Unmarshal(input, &params); err != nil {
        log.Printf("Failed to parse: %v", err)
        return "", err
    }
    
    log.Printf("Tool input (parsed): %+v", params)
    // ...
}
```

### 4. 使用调试器

使用 Delve 调试器：

```bash
# 安装 Delve
go install github.com/go-delve/delve/cmd/dlv@latest

# 启动调试
dlv debug read.go -- --verbose

# 设置断点
(dlv) break main.main
(dlv) break Agent.Run

# 运行
(dlv) continue

# 查看变量
(dlv) print conversation
(dlv) print message
```

### 5. 单元测试

编写测试验证工具行为：

```go
func TestReadFile(t *testing.T) {
    // 创建测试文件
    testFile := "test_file.txt"
    testContent := "test content"
    os.WriteFile(testFile, []byte(testContent), 0644)
    defer os.Remove(testFile)
    
    // 准备输入
    input := ReadFileInput{Path: testFile}
    inputJSON, _ := json.Marshal(input)
    
    // 调用工具
    result, err := ReadFile(inputJSON)
    
    // 验证结果
    if err != nil {
        t.Fatalf("ReadFile failed: %v", err)
    }
    if result != testContent {
        t.Errorf("Expected %q, got %q", testContent, result)
    }
}
```

### 6. 模拟 API 调用

测试时使用 mock client：

```go
type MockClient struct {
    Response *anthropic.Message
    Error    error
}

func (m *MockClient) Messages.New(ctx context.Context, params anthropic.MessageNewParams) (*anthropic.Message, error) {
    return m.Response, m.Error
}

func TestAgentWithMock(t *testing.T) {
    mockClient := &MockClient{
        Response: &anthropic.Message{
            Content: []anthropic.ContentBlock{
                {Type: "text", Text: "Hello"},
            },
        },
    }
    
    agent := NewAgent(mockClient, mockGetUserMessage, tools, false)
    // 测试 agent 行为
}
```

## 安全考虑

### 1. 验证文件路径

防止路径遍历攻击：

```go
func ValidatePath(path string) error {
    // 禁止路径遍历
    if strings.Contains(path, "..") {
        return fmt.Errorf("path traversal not allowed")
    }
    
    // 禁止绝对路径
    if filepath.IsAbs(path) {
        return fmt.Errorf("absolute paths not allowed")
    }
    
    // 确保路径在工作目录内
    absPath, err := filepath.Abs(path)
    if err != nil {
        return err
    }
    
    workDir, _ := os.Getwd()
    if !strings.HasPrefix(absPath, workDir) {
        return fmt.Errorf("path outside working directory")
    }
    
    return nil
}

func ReadFile(input json.RawMessage) (string, error) {
    var params ReadFileInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    // 验证路径
    if err := ValidatePath(params.Path); err != nil {
        return "", err
    }
    
    // 安全地读取文件
    content, err := os.ReadFile(params.Path)
    // ...
}
```

### 2. 限制命令执行

对 bash 工具添加安全限制：

```go
func Bash(input json.RawMessage) (string, error) {
    var params BashInput
    if err := json.Unmarshal(input, &params); err != nil {
        return "", err
    }
    
    // 可选：检查危险命令
    dangerousCommands := []string{"rm -rf /", ":(){ :|:& };:", "mkfs"}
    for _, dangerous := range dangerousCommands {
        if strings.Contains(params.Command, dangerous) {
            return "", fmt.Errorf("dangerous command not allowed")
        }
    }
    
    // 设置超时
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    cmd := exec.CommandContext(ctx, "bash", "-c", params.Command)
    output, err := cmd.CombinedOutput()
    
    // ...
}
```

### 3. 保护敏感信息

不要在日志中记录敏感信息：

```go
func LogSafely(message string, params map[string]interface{}) {
    // 过滤敏感字段
    sensitiveKeys := []string{"password", "api_key", "token", "secret"}
    
    safParams := make(map[string]interface{})
    for k, v := range params {
        isSensitive := false
        for _, sensitive := range sensitiveKeys {
            if strings.Contains(strings.ToLower(k), sensitive) {
                isSensitive = true
                break
            }
        }
        
        if isSensitive {
            safParams[k] = "***REDACTED***"
        } else {
            safParams[k] = v
        }
    }
    
    log.Printf("%s: %+v", message, safParams)
}
```

### 4. 环境变量安全

安全地处理 API 密钥：

```go
func main() {
    // 检查 API 密钥
    apiKey := os.Getenv("ANTHROPIC_API_KEY")
    if apiKey == "" {
        log.Fatal("ANTHROPIC_API_KEY environment variable not set")
    }
    
    // 不要在日志中打印密钥
    if verbose {
        log.Println("API key loaded from environment")
        // 不要这样做：log.Printf("API key: %s", apiKey)
    }
    
    client := anthropic.NewClient()
    // ...
}
```

## 代码质量

### 1. 命名规范

**使用清晰、描述性的名称：**

```go
// 好的命名
func ReadFile(input json.RawMessage) (string, error)
func GenerateSchema[T any]() anthropic.ToolInputSchemaParam
var ReadFileDefinition ToolDefinition

// 不好的命名
func rf(i json.RawMessage) (string, error)
func gen[T any]() anthropic.ToolInputSchemaParam
var rfd ToolDefinition
```

**遵循 Go 命名约定：**
- 导出的标识符首字母大写
- 私有标识符首字母小写
- 接口名通常以 -er 结尾
- 包名使用小写单词

### 2. 函数设计

**保持函数简短：**

```go
// 好：单一职责
func ReadFile(input json.RawMessage) (string, error) {
    params, err := parseReadFileInput(input)
    if err != nil {
        return "", err
    }
    
    if err := validatePath(params.Path); err != nil {
        return "", err
    }
    
    return readFileContent(params.Path)
}

// 辅助函数
func parseReadFileInput(input json.RawMessage) (*ReadFileInput, error) { /* ... */ }
func validatePath(path string) error { /* ... */ }
func readFileContent(path string) (string, error) { /* ... */ }
```

**避免深层嵌套：**

```go
// 好：提前返回
func ProcessFile(path string) error {
    if path == "" {
        return fmt.Errorf("path is empty")
    }
    
    content, err := os.ReadFile(path)
    if err != nil {
        return err
    }
    
    if len(content) == 0 {
        return fmt.Errorf("file is empty")
    }
    
    return processContent(content)
}

// 不好：深层嵌套
func ProcessFile(path string) error {
    if path != "" {
        content, err := os.ReadFile(path)
        if err == nil {
            if len(content) > 0 {
                return processContent(content)
            } else {
                return fmt.Errorf("file is empty")
            }
        } else {
            return err
        }
    } else {
        return fmt.Errorf("path is empty")
    }
}
```

### 3. 错误处理

**始终检查错误：**

```go
// 好
content, err := os.ReadFile(path)
if err != nil {
    return "", fmt.Errorf("failed to read file: %w", err)
}

// 不好
content, _ := os.ReadFile(path)
```

**提供上下文：**

```go
// 好：包含上下文信息
if err != nil {
    return "", fmt.Errorf("failed to read file %s: %w", path, err)
}

// 不好：丢失上下文
if err != nil {
    return "", err
}
```

### 4. 注释

**为导出的函数添加文档注释：**

```go
// ReadFile reads the contents of a file at the given path.
// It returns the file contents as a string, or an error if the file
// cannot be read.
func ReadFile(input json.RawMessage) (string, error) {
    // ...
}
```

**解释复杂逻辑：**

```go
// 检查是否有工具调用需要处理
// 我们需要收集所有工具调用的结果，然后一次性发送回 Claude
// 这样可以减少 API 调用次数
var toolResults []anthropic.ContentBlockParamUnion
for _, content := range message.Content {
    if content.Type == "tool_use" {
        // 执行工具并收集结果
        result := executeToolAndGetResult(content)
        toolResults = append(toolResults, result)
    }
}
```

### 5. 代码复用

**提取公共逻辑：**

```go
// 公共的 Schema 生成函数
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

// 所有工具都使用这个函数
var ReadFileInputSchema = GenerateSchema[ReadFileInput]()
var ListFilesInputSchema = GenerateSchema[ListFilesInput]()
var BashInputSchema = GenerateSchema[BashInput]()
```

## 测试策略

### 1. 单元测试

测试单个函数：

```go
func TestGenerateSchema(t *testing.T) {
    type TestInput struct {
        Name string `json:"name" jsonschema_description:"Test name"`
        Age  int    `json:"age" jsonschema_description:"Test age"`
    }
    
    schema := GenerateSchema[TestInput]()
    
    if schema.Properties == nil {
        t.Error("Expected non-nil properties")
    }
    
    // 验证 schema 包含预期字段
    // ...
}
```

### 2. 集成测试

测试工具与 Agent 的集成：

```go
func TestAgentWithTools(t *testing.T) {
    // 创建测试文件
    testFile := "test.txt"
    os.WriteFile(testFile, []byte("test"), 0644)
    defer os.Remove(testFile)
    
    // 创建 Agent
    tools := []ToolDefinition{ReadFileDefinition}
    agent := NewAgent(mockClient, mockGetUserMessage, tools, false)
    
    // 运行 Agent
    err := agent.Run(context.Background())
    if err != nil {
        t.Fatalf("Agent failed: %v", err)
    }
    
    // 验证结果
    // ...
}
```

### 3. 表驱动测试

测试多个场景：

```go
func TestValidatePath(t *testing.T) {
    tests := []struct {
        name    string
        path    string
        wantErr bool
    }{
        {"valid relative path", "file.txt", false},
        {"valid nested path", "dir/file.txt", false},
        {"path traversal", "../file.txt", true},
        {"absolute path", "/etc/passwd", true},
        {"current dir", ".", false},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidatePath(tt.path)
            if (err != nil) != tt.wantErr {
                t.Errorf("ValidatePath(%q) error = %v, wantErr %v", 
                    tt.path, err, tt.wantErr)
            }
        })
    }
}
```

## 工具开发检查清单

在发布工具之前，确保：

- [ ] 工具有清晰的名称和描述
- [ ] 所有参数都有 `jsonschema_description` 标签
- [ ] 输入参数经过验证
- [ ] 错误信息清晰且有用
- [ ] 添加了适当的日志记录
- [ ] 处理了边界情况
- [ ] 编写了单元测试
- [ ] 测试了错误场景
- [ ] 考虑了安全问题
- [ ] 添加了文档注释
- [ ] 性能可接受
- [ ] 与现有工具集成良好

## 常见陷阱

### 1. 忘记处理错误

```go
// 错误：忽略错误
content, _ := os.ReadFile(path)

// 正确：处理错误
content, err := os.ReadFile(path)
if err != nil {
    return "", fmt.Errorf("failed to read file: %w", err)
}
```

### 2. 资源泄漏

```go
// 错误：忘记关闭文件
file, _ := os.Open(path)
content, _ := io.ReadAll(file)

// 正确：使用 defer 关闭
file, err := os.Open(path)
if err != nil {
    return "", err
}
defer file.Close()
content, err := io.ReadAll(file)
```

### 3. 并发问题

```go
// 错误：共享状态没有保护
var counter int
func IncrementCounter() {
    counter++ // 不安全
}

// 正确：使用互斥锁
var (
    counter int
    mu      sync.Mutex
)
func IncrementCounter() {
    mu.Lock()
    defer mu.Unlock()
    counter++
}
```

### 4. 过度优化

```go
// 不必要的优化
func ProcessSmallFile(path string) (string, error) {
    // 对于小文件，简单的 ReadFile 就足够了
    return os.ReadFile(path)
}

// 不要过早优化
// 先让代码工作，然后在需要时优化
```

## 总结

遵循这些最佳实践将帮助你：

1. **代码质量**：编写清晰、可维护的代码
2. **可靠性**：通过良好的错误处理和测试提高可靠性
3. **性能**：避免常见的性能问题
4. **安全性**：保护系统免受常见攻击
5. **可调试性**：使用日志和调试工具快速定位问题

## 下一步

- 查看 [创建自定义工具](creating-tools.md) 了解工具开发的完整流程
- 阅读 [错误处理指南](error-handling.md) 深入了解错误处理
- 参考 [API 参考文档](../api-reference/agent.md) 了解 Agent API 详情
- 学习 [调试技巧](../troubleshooting/debugging.md) 提高问题排查能力
