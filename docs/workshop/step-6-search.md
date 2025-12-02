# 步骤 6：代码搜索

## 学习目标

- 理解如何集成外部工具（ripgrep）
- 掌握搜索参数和选项的处理
- 学习搜索结果的格式化和限制
- 了解正则表达式搜索的实现
- 认识高性能搜索工具的价值

## 背景知识

在大型代码库中查找特定代码是常见需求。虽然可以用 `bash` 工具执行 `grep`，但专门的代码搜索工具更强大。在这一步中，我们将集成 **ripgrep (rg)**，一个极快的代码搜索工具。

### 为什么选择 ripgrep？

ripgrep 的优势：
- **速度快**：比 grep 快很多倍
- **智能过滤**：自动跳过 .gitignore 中的文件
- **彩色输出**：易于阅读（虽然我们会禁用）
- **正则表达式**：支持强大的模式匹配
- **文件类型过滤**：可以只搜索特定类型的文件

### 搜索场景

Claude 可以使用代码搜索来：
- 查找函数定义：`func NewAgent`
- 查找变量使用：`verbose`
- 查找导入语句：`import.*anthropic`
- 查找注释：`// TODO`
- 查找错误处理：`if err != nil`

## 实现步骤

### 1. 前置要求

确保系统安装了 ripgrep：

```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
apt install ripgrep

# 验证安装
rg --version
```

### 2. CodeSearch 工具定义

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

**Description 要点**：
- 说明使用 ripgrep
- 列举常见用途
- 提示可用的过滤选项

### 3. 输入参数定义

```go
type CodeSearchInput struct {
	Pattern       string `json:"pattern" jsonschema_description:"The search pattern or regex to look for"`
	Path          string `json:"path,omitempty" jsonschema_description:"Optional path to search in (file or directory)"`
	FileType      string `json:"file_type,omitempty" jsonschema_description:"Optional file extension to limit search to (e.g., 'go', 'js', 'py')"`
	CaseSensitive bool   `json:"case_sensitive,omitempty" jsonschema_description:"Whether the search should be case sensitive (default: false)"`
}

var CodeSearchInputSchema = GenerateSchema[CodeSearchInput]()
```

**参数说明**：
- `Pattern`：必需，搜索模式（支持正则表达式）
- `Path`：可选，限制搜索范围
- `FileType`：可选，只搜索特定类型的文件
- `CaseSensitive`：可选，是否区分大小写（默认不区分）

### 4. CodeSearch 工具实现

```go
func CodeSearch(input json.RawMessage) (string, error) {
	codeSearchInput := CodeSearchInput{}
	err := json.Unmarshal(input, &codeSearchInput)
	if err != nil {
		return "", err
	}

	// 验证必需参数
	if codeSearchInput.Pattern == "" {
		log.Printf("CodeSearch failed: pattern is required")
		return "", fmt.Errorf("pattern is required")
	}

	log.Printf("Searching for pattern: %s", codeSearchInput.Pattern)

	// 构建 ripgrep 命令
	args := []string{"rg", "--line-number", "--with-filename", "--color=never"}

	// 添加大小写敏感性标志
	if !codeSearchInput.CaseSensitive {
		args = append(args, "--ignore-case")
	}

	// 添加文件类型过滤
	if codeSearchInput.FileType != "" {
		args = append(args, "--type", codeSearchInput.FileType)
	}

	// 添加搜索模式
	args = append(args, codeSearchInput.Pattern)

	// 添加搜索路径
	if codeSearchInput.Path != "" {
		args = append(args, codeSearchInput.Path)
	} else {
		args = append(args, ".")
	}

	// 执行命令
	cmd := exec.Command(args[0], args[1:]...)
	output, err := cmd.Output()
	
	// ripgrep 返回退出码 1 表示没有匹配，这不是错误
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
	
	// 限制输出，避免过多结果
	if len(lines) > 50 {
		result = strings.Join(lines[:50], "\n") + 
			fmt.Sprintf("\n... (showing first 50 of %d matches)", len(lines))
	}
	
	return result, nil
}
```

