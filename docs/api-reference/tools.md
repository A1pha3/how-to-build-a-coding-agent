# 工具 API 参考

## 概述

本文档详细说明了项目中所有内置工具的 API 接口。每个工具都遵循统一的 `ToolDefinition` 结构，可以被 Agent 调用以扩展 Claude 的能力。

工具系统允许 Claude 执行各种操作，包括：
- 文件系统操作（读取、列表、编辑）
- Shell 命令执行
- 代码搜索

## ToolDefinition 结构

所有工具都使用以下统一结构定义：

```go
type ToolDefinition struct {
    Name        string                         // 工具名称
    Description string                         // 工具描述
    InputSchema anthropic.ToolInputSchemaParam // 输入参数的 JSON Schema
    Function    func(input json.RawMessage) (string, error) // 工具执行函数
}
```

**字段说明：**

- `Name`: 工具的唯一标识符，Claude 使用此名称调用工具
- `Description`: 工具功能的自然语言描述，帮助 Claude 理解何时使用该工具
- `InputSchema`: 使用 JSON Schema 定义的输入参数结构
- `Function`: 实际执行工具逻辑的函数，接收 JSON 输入并返回字符串结果或错误

## 内置工具列表

本项目提供以下内置工具：

1. [read_file](#read_file) - 读取文件内容
2. [list_files](#list_files) - 列出目录中的文件
3. [bash](#bash) - 执行 Shell 命令
4. [edit_file](#edit_file) - 编辑文件内容
5. [code_search](#code_search) - 搜索代码模式

---

## read_file

读取指定文件的完整内容。

### 定义

```go
var ReadFileDefinition = ToolDefinition{
    Name:        "read_file",
    Description: "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names.",
    InputSchema: ReadFileInputSchema,
    Function:    ReadFile,
}
```

### 输入参数

```go
type ReadFileInput struct {
    Path string `json:"path" jsonschema_description:"The relative path of a file in the working directory."`
}
```

**参数说明：**

- `path` (必需): 相对于工作目录的文件路径

### 返回值

- **成功**: 返回文件的完整文本内容
- **失败**: 返回错误（如文件不存在、权限不足等）

### 实现函数

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

### 使用示例

**Claude 调用：**
```json
{
  "name": "read_file",
  "input": {
    "path": "README.md"
  }
}
```

**返回结果：**
```
# AI Programming Assistant Workshop

This is a workshop project...
```

### 错误处理

常见错误：
- 文件不存在: `open README.md: no such file or directory`
- 权限不足: `open /etc/shadow: permission denied`
- 路径是目录: `read .: is a directory`

### 最佳实践

1. 使用相对路径而非绝对路径
2. 确保文件存在后再读取
3. 注意大文件可能导致响应过长
4. 不要用于读取二进制文件

---

## list_files

列出指定目录中的所有文件和子目录。

### 定义

```go
var ListFilesDefinition = ToolDefinition{
    Name:        "list_files",
    Description: "List files and directories at a given path. If no path is provided, lists files in the current directory.",
    InputSchema: ListFilesInputSchema,
    Function:    ListFiles,
}
```

### 输入参数

```go
type ListFilesInput struct {
    Path string `json:"path,omitempty" jsonschema_description:"Optional relative path to list files from. Defaults to current directory if not provided."`
}
```

**参数说明：**

- `path` (可选): 要列出的目录路径，默认为当前目录 `.`

### 返回值

- **成功**: 返回 JSON 数组格式的文件列表，目录名以 `/` 结尾
- **失败**: 返回错误

### 实现函数

```go
func ListFiles(input json.RawMessage) (string, error) {
    listFilesInput := ListFilesInput{}
    err := json.Unmarshal(input, &listFilesInput)
    if err != nil {
        panic(err)
    }

    dir := "."
    if listFilesInput.Path != "" {
        dir = listFilesInput.Path
    }

    log.Printf("Listing files in directory: %s", dir)
    var files []string
    err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }

        relPath, err := filepath.Rel(dir, path)
        if err != nil {
            return err
        }

        // Skip .devenv directory and its contents
        if info.IsDir() && (relPath == ".devenv" || strings.HasPrefix(relPath, ".devenv/")) {
            return filepath.SkipDir
        }

        if relPath != "." {
            if info.IsDir() {
                files = append(files, relPath+"/")
            } else {
                files = append(files, relPath)
            }
        }
        return nil
    })

    if err != nil {
        log.Printf("Failed to list files in %s: %v", dir, err)
        return "", err
    }

    result, err := json.Marshal(files)
    if err != nil {
        return "", err
    }

    log.Printf("Successfully listed %d files in %s", len(files), dir)
    return string(result), nil
}
```

### 使用示例

**Claude 调用（列出当前目录）：**
```json
{
  "name": "list_files",
  "input": {}
}
```

**返回结果：**
```json
["README.md","go.mod","go.sum","chat.go","read.go","docs/","prompts/"]
```

**Claude 调用（列出指定目录）：**
```json
{
  "name": "list_files",
  "input": {
    "path": "docs"
  }
}
```

**返回结果：**
```json
["README.md","getting-started/","architecture/","workshop/"]
```

### 行为特性

- 递归遍历所有子目录
- 自动跳过 `.devenv` 目录
- 目录名以 `/` 结尾便于识别
- 返回相对于指定目录的路径

### 错误处理

常见错误：
- 目录不存在: `lstat docs: no such file or directory`
- 权限不足: `open /root: permission denied`

### 最佳实践

1. 先列出目录结构，再决定读取哪些文件
2. 注意大型目录可能返回大量文件
3. 使用返回的路径直接传递给 `read_file`

---

## bash

执行 Shell 命令并返回输出结果。

### 定义

```go
var BashDefinition = ToolDefinition{
    Name:        "bash",
    Description: "Execute a bash command and return its output. Use this to run shell commands.",
    InputSchema: BashInputSchema,
    Function:    Bash,
}
```

### 输入参数

```go
type BashInput struct {
    Command string `json:"command" jsonschema_description:"The bash command to execute."`
}
```

**参数说明：**

- `command` (必需): 要执行的 bash 命令字符串

### 返回值

- **成功**: 返回命令的标准输出（去除首尾空白）
- **失败**: 返回包含错误信息和输出的字符串（不返回 error）

### 实现函数

```go
func Bash(input json.RawMessage) (string, error) {
    bashInput := BashInput{}
    err := json.Unmarshal(input, &bashInput)
    if err != nil {
        return "", err
    }

    log.Printf("Executing bash command: %s", bashInput.Command)
    cmd := exec.Command("bash", "-c", bashInput.Command)
    output, err := cmd.CombinedOutput()
    if err != nil {
        log.Printf("Bash command failed: %v", err)
        return fmt.Sprintf("Command failed with error: %s\nOutput: %s", err.Error(), string(output)), nil
    }

    log.Printf("Bash command executed successfully, output length: %d chars", len(output))
    return strings.TrimSpace(string(output)), nil
}
```

### 使用示例

**Claude 调用（成功执行）：**
```json
{
  "name": "bash",
  "input": {
    "command": "ls -la"
  }
}
```

**返回结果：**
```
total 48
drwxr-xr-x  10 user  staff   320 Jan  1 10:00 .
drwxr-xr-x   5 user  staff   160 Jan  1 09:00 ..
-rw-r--r--   1 user  staff  1234 Jan  1 10:00 README.md
```

**Claude 调用（命令失败）：**
```json
{
  "name": "bash",
  "input": {
    "command": "cat nonexistent.txt"
  }
}
```

**返回结果：**
```
Command failed with error: exit status 1
Output: cat: nonexistent.txt: No such file or directory
```

### 安全考虑

⚠️ **重要安全提示：**

1. 此工具执行任意 Shell 命令，具有潜在危险
2. 不应在不受信任的环境中使用
3. 命令以当前用户权限执行
4. 可能修改文件系统、网络等

### 错误处理

- 命令执行失败时，返回错误信息和输出，但不抛出 Go error
- 这样 Claude 可以看到错误信息并做出响应
- 同时捕获 stdout 和 stderr

### 最佳实践

1. 优先使用专用工具（如 `read_file`）而非 bash 命令
2. 避免执行长时间运行的命令
3. 注意命令可能产生大量输出
4. 使用简单、安全的命令

---

## edit_file

通过字符串替换编辑文件内容，或创建新文件。

### 定义

```go
var EditFileDefinition = ToolDefinition{
    Name: "edit_file",
    Description: `Make edits to a text file.

Replaces 'old_str' with 'new_str' in the given file. 'old_str' and 'new_str' MUST be different from each other.

If the file specified with path doesn't exist, it will be created.`,
    InputSchema: EditFileInputSchema,
    Function:    EditFile,
}
```

### 输入参数

```go
type EditFileInput struct {
    Path   string `json:"path" jsonschema_description:"The path to the file"`
    OldStr string `json:"old_str" jsonschema_description:"Text to search for - must match exactly and must only have one match exactly"`
    NewStr string `json:"new_str" jsonschema_description:"Text to replace old_str with"`
}
```

**参数说明：**

- `path` (必需): 文件路径
- `old_str` (必需): 要替换的原始文本，必须在文件中精确匹配且唯一
- `new_str` (必需): 替换后的新文本，必须与 `old_str` 不同

### 返回值

- **成功**: 返回 `"OK"` 或创建文件的成功消息
- **失败**: 返回错误

### 实现函数

```go
func EditFile(input json.RawMessage) (string, error) {
    editFileInput := EditFileInput{}
    err := json.Unmarshal(input, &editFileInput)
    if err != nil {
        return "", err
    }

    if editFileInput.Path == "" || editFileInput.OldStr == editFileInput.NewStr {
        log.Printf("EditFile failed: invalid input parameters")
        return "", fmt.Errorf("invalid input parameters")
    }

    log.Printf("Editing file: %s (replacing %d chars with %d chars)", editFileInput.Path, len(editFileInput.OldStr), len(editFileInput.NewStr))
    content, err := os.ReadFile(editFileInput.Path)
    if err != nil {
        if os.IsNotExist(err) && editFileInput.OldStr == "" {
            log.Printf("File does not exist, creating new file: %s", editFileInput.Path)
            return createNewFile(editFileInput.Path, editFileInput.NewStr)
        }
        log.Printf("Failed to read file %s: %v", editFileInput.Path, err)
        return "", err
    }

    oldContent := string(content)

    // Special case: if old_str is empty, we're appending to the file
    var newContent string
    if editFileInput.OldStr == "" {
        newContent = oldContent + editFileInput.NewStr
    } else {
        // Count occurrences first to ensure we have exactly one match
        count := strings.Count(oldContent, editFileInput.OldStr)
        if count == 0 {
            log.Printf("EditFile failed: old_str not found in file %s", editFileInput.Path)
            return "", fmt.Errorf("old_str not found in file")
        }
        if count > 1 {
            log.Printf("EditFile failed: old_str found %d times in file %s, must be unique", count, editFileInput.Path)
            return "", fmt.Errorf("old_str found %d times in file, must be unique", count)
        }

        newContent = strings.Replace(oldContent, editFileInput.OldStr, editFileInput.NewStr, 1)
    }

    err = os.WriteFile(editFileInput.Path, []byte(newContent), 0644)
    if err != nil {
        log.Printf("Failed to write file %s: %v", editFileInput.Path, err)
        return "", err
    }

    log.Printf("Successfully edited file %s", editFileInput.Path)
    return "OK", nil
}
```

### 使用示例

**示例 1：替换文本**

原文件内容（`config.txt`）：
```
port=8080
host=localhost
```

Claude 调用：
```json
{
  "name": "edit_file",
  "input": {
    "path": "config.txt",
    "old_str": "port=8080",
    "new_str": "port=3000"
  }
}
```

结果：
```
port=3000
host=localhost
```

**示例 2：创建新文件**

Claude 调用：
```json
{
  "name": "edit_file",
  "input": {
    "path": "new_file.txt",
    "old_str": "",
    "new_str": "Hello, World!"
  }
}
```

结果：创建包含 "Hello, World!" 的新文件

**示例 3：追加内容**

原文件内容：
```
Line 1
```

Claude 调用：
```json
{
  "name": "edit_file",
  "input": {
    "path": "file.txt",
    "old_str": "",
    "new_str": "\nLine 2"
  }
}
```

结果：
```
Line 1
Line 2
```

### 特殊行为

1. **创建文件**: 当文件不存在且 `old_str` 为空时，创建新文件
2. **追加内容**: 当文件存在且 `old_str` 为空时，追加到文件末尾
3. **唯一性检查**: `old_str` 必须在文件中恰好出现一次

### 错误处理

常见错误：
- `old_str not found in file`: 要替换的文本不存在
- `old_str found N times in file, must be unique`: 文本出现多次，无法确定替换位置
- `invalid input parameters`: `old_str` 和 `new_str` 相同

### 最佳实践

1. 包含足够的上下文使 `old_str` 唯一
2. 先用 `read_file` 确认文件内容
3. 使用多行字符串进行精确匹配
4. 注意空白字符（空格、制表符、换行）

---

## code_search

使用 ripgrep 搜索代码模式。

### 定义

```go
var CodeSearchDefinition = ToolDefinition{
    Name: "code_search",
    Description: `Search for code patterns using ripgrep (rg).

Use this to find code patterns, function definitions, variable usage, or any text in the codebase.
You can search by pattern, file type, or directory.`,
    InputSchema: CodeSearchInputSchema,
    Function:    CodeSearch,
}
```

### 输入参数

```go
type CodeSearchInput struct {
    Pattern       string `json:"pattern" jsonschema_description:"The search pattern or regex to look for"`
    Path          string `json:"path,omitempty" jsonschema_description:"Optional path to search in (file or directory)"`
    FileType      string `json:"file_type,omitempty" jsonschema_description:"Optional file extension to limit search to (e.g., 'go', 'js', 'py')"`
    CaseSensitive bool   `json:"case_sensitive,omitempty" jsonschema_description:"Whether the search should be case sensitive (default: false)"`
}
```

**参数说明：**

- `pattern` (必需): 搜索模式或正则表达式
- `path` (可选): 搜索路径，默认为当前目录
- `file_type` (可选): 限制文件类型，如 `"go"`, `"js"`, `"py"`
- `case_sensitive` (可选): 是否区分大小写，默认 `false`

### 返回值

- **成功**: 返回匹配结果，格式为 `文件名:行号:匹配内容`
- **无匹配**: 返回 `"No matches found"`
- **失败**: 返回错误

### 实现函数

```go
func CodeSearch(input json.RawMessage) (string, error) {
    codeSearchInput := CodeSearchInput{}
    err := json.Unmarshal(input, &codeSearchInput)
    if err != nil {
        return "", err
    }

    if codeSearchInput.Pattern == "" {
        log.Printf("CodeSearch failed: pattern is required")
        return "", fmt.Errorf("pattern is required")
    }

    log.Printf("Searching for pattern: %s", codeSearchInput.Pattern)

    // Build ripgrep command
    args := []string{"rg", "--line-number", "--with-filename", "--color=never"}

    // Add case sensitivity flag
    if !codeSearchInput.CaseSensitive {
        args = append(args, "--ignore-case")
    }

    // Add file type filter if specified
    if codeSearchInput.FileType != "" {
        args = append(args, "--type", codeSearchInput.FileType)
    }

    // Add pattern
    args = append(args, codeSearchInput.Pattern)

    // Add path if specified
    if codeSearchInput.Path != "" {
        args = append(args, codeSearchInput.Path)
    } else {
        args = append(args, ".")
    }

    cmd := exec.Command(args[0], args[1:]...)
    output, err := cmd.Output()
    
    // ripgrep returns exit code 1 when no matches are found, which is not an error
    if err != nil {
        if exitError, ok := err.(*exec.ExitError); ok && exitError.ExitCode() == 1 {
            log.Printf("No matches found for pattern: %s", codeSearchInput.Pattern)
            return "No matches found", nil
        }
        log.Printf("Ripgrep command failed: %v", err)
        return "", fmt.Errorf("search failed: %w", err)
    }

    result := strings.TrimSpace(string(output))
    lines := strings.Split(result, "\n")
    
    log.Printf("Found %d matches for pattern: %s", len(lines), codeSearchInput.Pattern)
    
    // Limit output to prevent overwhelming responses
    if len(lines) > 50 {
        result = strings.Join(lines[:50], "\n") + fmt.Sprintf("\n... (showing first 50 of %d matches)", len(lines))
    }
    
    return result, nil
}
```

### 使用示例

**示例 1：简单文本搜索**

Claude 调用：
```json
{
  "name": "code_search",
  "input": {
    "pattern": "func main"
  }
}
```

返回结果：
```
chat.go:10:func main() {
read.go:10:func main() {
list_files.go:10:func main() {
```

**示例 2：按文件类型搜索**

Claude 调用：
```json
{
  "name": "code_search",
  "input": {
    "pattern": "Agent",
    "file_type": "go"
  }
}
```

返回结果：
```
chat.go:25:type Agent struct {
chat.go:30:func NewAgent(client *anthropic.Client) *Agent {
read.go:35:type Agent struct {
```

**示例 3：在特定目录搜索**

Claude 调用：
```json
{
  "name": "code_search",
  "input": {
    "pattern": "TODO",
    "path": "docs"
  }
}
```

**示例 4：区分大小写搜索**

Claude 调用：
```json
{
  "name": "code_search",
  "input": {
    "pattern": "Agent",
    "case_sensitive": true
  }
}
```

### 依赖要求

此工具需要系统安装 `ripgrep` (rg)：

```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
apt-get install ripgrep

# 其他系统
# 参见 https://github.com/BurntSushi/ripgrep#installation
```

### 输出限制

- 最多显示前 50 个匹配结果
- 超过 50 个时会显示总数提示
- 防止输出过长影响响应

### 最佳实践

1. 使用具体的搜索模式减少结果数量
2. 利用 `file_type` 过滤特定语言文件
3. 先在小范围目录搜索，再扩大范围
4. 使用正则表达式进行精确匹配

---

## 工具注册

### 注册工具到 Agent

```go
// 注册单个工具
tools := []ToolDefinition{ReadFileDefinition}

// 注册多个工具
tools := []ToolDefinition{
    ReadFileDefinition,
    ListFilesDefinition,
    BashDefinition,
    EditFileDefinition,
    CodeSearchDefinition,
}

agent := NewAgent(&client, getUserMessage, tools, verbose)
```

### 工具组合建议

**只读模式**（安全）：
```go
readOnlyTools := []ToolDefinition{
    ReadFileDefinition,
    ListFilesDefinition,
    CodeSearchDefinition,
}
```

**开发模式**（完整功能）：
```go
devTools := []ToolDefinition{
    ReadFileDefinition,
    ListFilesDefinition,
    BashDefinition,
    EditFileDefinition,
    CodeSearchDefinition,
}
```

**文件操作模式**：
```go
fileTools := []ToolDefinition{
    ReadFileDefinition,
    ListFilesDefinition,
    EditFileDefinition,
}
```

## Schema 生成

所有工具的输入 Schema 都通过 `GenerateSchema` 函数自动生成：

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

### 使用示例

```go
type MyToolInput struct {
    Name  string `json:"name" jsonschema_description:"The name parameter"`
    Count int    `json:"count,omitempty" jsonschema_description:"Optional count"`
}

var MyToolInputSchema = GenerateSchema[MyToolInput]()
```

## 工具执行流程

1. **Claude 决定使用工具**: 基于对话上下文和工具描述
2. **生成工具调用**: Claude 生成包含工具名称和参数的 JSON
3. **Agent 接收调用**: 从响应中提取 `tool_use` 内容块
4. **查找工具**: 在注册的工具列表中查找匹配的工具
5. **执行工具**: 调用工具的 `Function` 并传入参数
6. **返回结果**: 将结果或错误返回给 Claude
7. **Claude 处理结果**: Claude 分析结果并继续对话

## 错误处理模式

### 工具内部错误

```go
func MyTool(input json.RawMessage) (string, error) {
    // 解析错误 - panic（不应发生）
    err := json.Unmarshal(input, &myInput)
    if err != nil {
        panic(err)
    }
    
    // 业务逻辑错误 - 返回 error
    if myInput.Path == "" {
        return "", fmt.Errorf("path is required")
    }
    
    // 操作失败 - 返回 error
    content, err := os.ReadFile(myInput.Path)
    if err != nil {
        return "", err
    }
    
    return string(content), nil
}
```

### Agent 错误处理

```go
// Agent 捕获工具错误并转换为工具结果
if toolError != nil {
    toolResults = append(toolResults, 
        anthropic.NewToolResultBlock(toolUse.ID, toolError.Error(), true))
} else {
    toolResults = append(toolResults, 
        anthropic.NewToolResultBlock(toolUse.ID, toolResult, false))
}
```

## 相关文档

- [Agent API 参考](agent.md) - 了解 Agent 如何管理工具
- [类型定义参考](types.md) - 查看相关类型定义
- [工具系统架构](../architecture/tool-system.md) - 深入理解工具系统设计
- [创建自定义工具](../guides/creating-tools.md) - 学习如何创建新工具
