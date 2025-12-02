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


### 5. 注册工具

```go
func main() {
	// ... 之前的代码 ...

	tools := []ToolDefinition{
		ReadFileDefinition, 
		ListFilesDefinition, 
		BashDefinition,
		CodeSearchDefinition,
	}
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

注意：这个版本没有包含 `EditFileDefinition`，因为它专注于搜索功能。

## 运行和测试

### 编译和运行

```bash
# 基本运行
go run code_search_tool.go

# 启用详细日志
go run code_search_tool.go --verbose
```

### 示例对话 1：基本搜索

```
Chat with Claude (use 'ctrl-c' to quit)
You: 找出所有定义了 func main 的地方
tool: code_search({"pattern":"func main"})
result: chat.go:15:func main() {
read.go:18:func main() {
list_files.go:20:func main() {
bash_tool.go:22:func main() {
Claude: 项目中有 4 个文件定义了 main 函数：
- chat.go (第 15 行)
- read.go (第 18 行)
- list_files.go (第 20 行)
- bash_tool.go (第 22 行)
```

### 示例对话 2：搜索特定文件类型

```
You: 在 Go 文件中搜索 "error"
tool: code_search({"pattern":"error","file_type":"go"})
result: chat.go:45:	if err != nil {
read.go:89:	return "", fmt.Errorf("tool '%s' not found", toolUse.Name)
...
Claude: 在 Go 文件中找到多处 "error" 相关代码，主要是错误处理逻辑...
```

### 示例对话 3：正则表达式搜索

```
You: 找出所有的 TODO 注释
tool: code_search({"pattern":"//\\s*TODO"})
result: chat.go:10:// TODO: Add timeout support
read.go:55:// TODO: Implement caching
Claude: 找到 2 个 TODO 注释：
1. chat.go:10 - 添加超时支持
2. read.go:55 - 实现缓存
```

### 示例对话 4：限定目录搜索

```
You: 在 docs 目录中搜索 "Agent"
tool: code_search({"pattern":"Agent","path":"docs"})
result: docs/architecture/agent-design.md:1:# Agent 设计
docs/architecture/overview.md:15:Agent 是系统的核心组件
...
Claude: 在 docs 目录中找到多处 "Agent" 的引用...
```

### 示例对话 5：大小写敏感搜索

```
You: 搜索大写的 "README"
tool: code_search({"pattern":"README","case_sensitive":true})
result: docs/README.md:1:# 文档索引
go.mod:3:// See README.md for details
Claude: 找到 2 处大写的 "README"...
```

## 代码解析

### 核心概念

#### 1. ripgrep 命令构建

```go
args := []string{"rg", "--line-number", "--with-filename", "--color=never"}
```

基础参数说明：
- `rg`：ripgrep 命令
- `--line-number`：显示行号
- `--with-filename`：显示文件名
- `--color=never`：禁用颜色（便于解析）

#### 2. 动态参数添加

```go
if !codeSearchInput.CaseSensitive {
	args = append(args, "--ignore-case")
}

if codeSearchInput.FileType != "" {
	args = append(args, "--type", codeSearchInput.FileType)
}
```

根据用户输入动态构建命令：
- 默认不区分大小写
- 可选的文件类型过滤

#### 3. 退出码处理

```go
if exitError, ok := err.(*exec.ExitError); ok && exitError.ExitCode() == 1 {
	return "No matches found", nil
}
```

ripgrep 的退出码：
- `0`：找到匹配
- `1`：没有匹配（不是错误）
- `2`：真正的错误

我们需要区分"没有匹配"和"执行失败"。

#### 4. 结果限制

```go
if len(lines) > 50 {
	result = strings.Join(lines[:50], "\n") + 
		fmt.Sprintf("\n... (showing first 50 of %d matches)", len(lines))
}
```

限制输出的原因：
- 避免 Claude 处理过多数据
- 减少 API token 消耗
- 提高响应速度

### 关键代码段分析

#### 命令执行

```go
cmd := exec.Command(args[0], args[1:]...)
output, err := cmd.Output()
```

使用 `cmd.Output()` 而不是 `cmd.CombinedOutput()`：
- 只捕获 stdout
- stderr 通常包含警告，不需要
- 简化输出处理

#### 类型断言

```go
if exitError, ok := err.(*exec.ExitError); ok && exitError.ExitCode() == 1 {
```

Go 的类型断言模式：
- 检查 `err` 是否是 `*exec.ExitError` 类型
- 如果是，获取退出码
- 这是处理命令退出状态的标准方式

#### 结果格式

ripgrep 的输出格式：
```
文件名:行号:匹配内容
```

例如：
```
chat.go:15:func main() {
```

这种格式便于 Claude 理解和解释。

### 为什么这样设计？

**问：为什么不直接用 grep？**
答：
- ripgrep 更快（特别是大型代码库）
- 自动跳过 .gitignore 文件
- 更好的默认行为
- 更丰富的功能

**问：为什么默认不区分大小写？**
答：
- 更宽松的搜索通常更有用
- 用户可以明确指定区分大小写
- 符合大多数搜索工具的默认行为

**问：为什么限制 50 条结果？**
答：
- 太多结果对 Claude 没有帮助
- 减少 token 消耗
- 如果需要更多，用户可以缩小搜索范围

**问：如何处理二进制文件？**
答：ripgrep 默认跳过二进制文件，这正是我们想要的。

## ripgrep 高级功能

### 常用选项

```bash
# 只显示文件名
rg -l pattern

# 显示上下文（前后各 2 行）
rg -C 2 pattern

# 反向匹配（不包含 pattern 的行）
rg -v pattern

# 只匹配整个单词
rg -w pattern

# 显示匹配数量
rg -c pattern

# 搜索隐藏文件
rg --hidden pattern
```

### 文件类型

ripgrep 内置了很多文件类型：

```bash
# 查看所有支持的类型
rg --type-list

# 常用类型
rg --type go pattern      # Go 文件
rg --type js pattern      # JavaScript 文件
rg --type py pattern      # Python 文件
rg --type md pattern      # Markdown 文件
```

### 正则表达式

ripgrep 使用 Rust 的正则表达式引擎：

```bash
# 匹配函数定义
rg "func \w+\("

# 匹配 import 语句
rg "^import"

# 匹配 TODO 或 FIXME
rg "TODO|FIXME"

# 匹配数字
rg "\d+"
```

## 练习建议

1. **添加上下文行**：添加参数显示匹配行的上下文
   ```go
   Context int `json:"context,omitempty"`
   // 使用 -C 参数
   ```

2. **添加只显示文件名选项**：有时只需要知道哪些文件包含匹配
   ```go
   FilesOnly bool `json:"files_only,omitempty"`
   // 使用 -l 参数
   ```

3. **添加排除模式**：允许排除某些文件或目录
   ```go
   Exclude string `json:"exclude,omitempty"`
   // 使用 --glob '!pattern'
   ```

4. **实现替换功能**：结合搜索和编辑，实现全局替换

5. **添加搜索历史**：记录搜索模式，便于重复使用

6. **实现增量搜索**：支持在上次结果中继续搜索

## 常见问题

### Q: ripgrep 没有安装怎么办？

A: 可以回退到 grep：
```go
if _, err := exec.LookPath("rg"); err != nil {
	// 使用 grep 作为后备
	args = []string{"grep", "-rn", pattern, path}
}
```

### Q: 如何搜索包含特殊字符的模式？

A: 需要转义正则表达式特殊字符：
```go
import "regexp"
escapedPattern := regexp.QuoteMeta(pattern)
```

### Q: 搜索结果太多怎么办？

A: 建议用户：
- 使用更具体的模式
- 限制搜索目录
- 指定文件类型
- 使用正则表达式精确匹配

### Q: 如何搜索多行模式？

A: ripgrep 支持多行模式：
```bash
rg --multiline "func.*\n.*error"
```

### Q: 可以搜索压缩文件吗？

A: ripgrep 支持搜索压缩文件：
```bash
rg -z pattern file.gz
```

### Q: 如何提高搜索性能？

A: 
- 限制搜索目录
- 使用文件类型过滤
- 避免过于宽泛的正则表达式
- 使用 `--max-count` 限制每个文件的匹配数

## 工作坊总结

恭喜！你已经完成了整个工作坊的学习。让我们回顾一下学到的内容：

### 步骤回顾

1. **步骤 1：基础聊天** - Agent 结构和事件循环
2. **步骤 2：文件读取** - 工具系统和 Schema 生成
3. **步骤 3：文件列表** - 多工具管理和文件系统遍历
4. **步骤 4：命令执行** - Shell 命令和安全考虑
5. **步骤 5：文件编辑** - 字符串替换和文件创建
6. **步骤 6：代码搜索** - 外部工具集成和结果处理

### 核心概念

- **Agent 模式**：封装 AI 交互逻辑
- **工具系统**：扩展 AI 能力的机制
- **事件循环**：处理用户输入和工具调用
- **Schema 生成**：自动化工具接口定义
- **错误处理**：优雅地处理各种异常

### 下一步建议

1. **添加更多工具**：
   - 网络请求工具
   - 数据库查询工具
   - 图片处理工具

2. **改进现有工具**：
   - 添加缓存
   - 实现并发执行
   - 添加权限控制

3. **增强 Agent**：
   - 添加系统提示
   - 实现对话摘要
   - 支持多模态输入

4. **生产化**：
   - 添加认证和授权
   - 实现速率限制
   - 添加监控和日志

感谢你完成这个工作坊！希望你对构建 AI 编程助手有了更深入的理解。

## 相关资源

- [Anthropic Claude API 文档](https://docs.anthropic.com/)
- [ripgrep 官方文档](https://github.com/BurntSushi/ripgrep)
- [Go 标准库文档](https://pkg.go.dev/std)
- [JSON Schema 规范](https://json-schema.org/)
