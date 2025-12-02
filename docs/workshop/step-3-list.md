# 步骤 3：文件列表

## 学习目标

- 学习如何管理多个工具
- 掌握可选参数的处理方式
- 理解文件系统遍历的实现
- 了解工具之间的协同工作
- 学习 JSON 数据的返回格式

## 背景知识

在步骤 2 中，我们添加了 `read_file` 工具。但有一个问题：Claude 需要知道文件路径才能读取文件。如果用户问"这个项目有哪些文件？"，Claude 无法回答。

在这一步中，我们将添加 `list_files` 工具，让 Claude 能够：
- 列出目录中的文件和子目录
- 浏览项目结构
- 在读取文件前先了解有哪些文件可用

### 工具协同工作

有了 `list_files` 和 `read_file` 两个工具，Claude 可以：
1. 先用 `list_files` 查看有哪些文件
2. 根据文件名判断哪些文件可能包含所需信息
3. 用 `read_file` 读取相关文件
4. 综合信息回答用户问题

这展示了工具系统的强大之处：多个简单工具组合可以完成复杂任务。

## 实现步骤

### 1. 新增导入

```go
import (
	// ... 之前的导入 ...
	"path/filepath"
	"strings"
)
```

- `path/filepath`：跨平台的文件路径操作
- `strings`：字符串处理

### 2. ListFiles 工具定义

```go
var ListFilesDefinition = ToolDefinition{
	Name:        "list_files",
	Description: "List files and directories at a given path. If no path is provided, lists files in the current directory.",
	InputSchema: ListFilesInputSchema,
	Function:    ListFiles,
}
```

**Description 要点**：
- 说明工具的功能
- 指出路径参数是可选的
- 说明默认行为

### 3. 输入参数定义（可选参数）

```go
type ListFilesInput struct {
	Path string `json:"path,omitempty" jsonschema_description:"Optional relative path to list files from. Defaults to current directory if not provided."`
}

var ListFilesInputSchema = GenerateSchema[ListFilesInput]()
```

**关键点**：
- `omitempty` tag：如果字段为空，JSON 序列化时会省略
- 描述中明确说明这是可选参数
- 说明默认值是当前目录

### 4. ListFiles 工具实现

```go
func ListFiles(input json.RawMessage) (string, error) {
	listFilesInput := ListFilesInput{}
	err := json.Unmarshal(input, &listFilesInput)
	if err != nil {
		panic(err)
	}

	// 处理默认值
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

		// 跳过 .devenv 目录
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

	log.Printf("Successfully listed %d items in %s", len(files), dir)

	// 返回 JSON 格式的文件列表
	result, err := json.Marshal(files)
	if err != nil {
		return "", err
	}

	return string(result), nil
}
```


### 5. 注册多个工具

```go
func main() {
	// ... 之前的代码 ...

	tools := []ToolDefinition{ReadFileDefinition, ListFilesDefinition}
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

**关键点**：
- 工具列表现在包含两个工具
- 顺序不重要，Claude 会根据需要选择
- 可以轻松添加更多工具

## 运行和测试

### 编译和运行

```bash
# 基本运行
go run list_files.go

# 启用详细日志
go run list_files.go --verbose
```

### 示例对话 1：列出当前目录

```
Chat with Claude (use 'ctrl-c' to quit)
You: 这个项目有哪些文件？
tool: list_files({})
result: ["README.md","go.mod","go.sum","chat.go","read.go","list_files.go","docs/","prompts/"]
Claude: 这个项目包含以下文件和目录：

文件：
- README.md - 项目说明文档
- go.mod, go.sum - Go 模块依赖文件
- chat.go - 基础聊天程序
- read.go - 带文件读取功能的版本
- list_files.go - 当前版本（带文件列表功能）

目录：
- docs/ - 文档目录
- prompts/ - 提示词目录
```

### 示例对话 2：列出特定目录

```
You: docs 目录下有什么？
tool: list_files({"path":"docs"})
result: ["README.md","getting-started/","architecture/","workshop/"]
Claude: docs 目录包含：
- README.md - 文档主索引
- getting-started/ - 入门指南
- architecture/ - 架构文档
- workshop/ - 工作坊教程
```

### 示例对话 3：工具协同使用

```
You: 找出所有的 Go 源文件并告诉我它们的作用
tool: list_files({})
result: ["chat.go","read.go","list_files.go","bash_tool.go","edit_tool.go"]
tool: read_file({"path":"chat.go"})
result: package main...
tool: read_file({"path":"read.go"})
result: package main...
Claude: 我找到了 5 个 Go 源文件：

1. chat.go - 基础聊天程序，实现了与 Claude 的简单对话功能
2. read.go - 添加了文件读取工具的版本
3. list_files.go - 添加了文件列表工具的版本
4. bash_tool.go - 添加了命令执行工具的版本
5. edit_tool.go - 添加了文件编辑工具的版本

这些文件展示了工作坊的渐进式学习路径。
```

## 代码解析

### 核心概念

#### 1. filepath.Walk 函数

```go
err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
	// 处理每个文件/目录
	return nil
})
```

`filepath.Walk` 递归遍历目录树：
- 对每个文件和目录调用回调函数
- 回调函数返回 `nil` 继续遍历
- 返回 `filepath.SkipDir` 跳过当前目录
- 返回其他错误会停止遍历

#### 2. 相对路径处理

```go
relPath, err := filepath.Rel(dir, path)
```

`filepath.Rel` 计算相对路径：
- 如果 `dir` 是 "."，`path` 是 "./docs/README.md"
- 结果是 "docs/README.md"

这样返回的路径更简洁，用户更容易理解。

#### 3. 目录过滤

```go
if info.IsDir() && (relPath == ".devenv" || strings.HasPrefix(relPath, ".devenv/")) {
	return filepath.SkipDir
}
```

跳过不需要的目录：
- `.devenv` 是开发环境目录，通常很大且不相关
- 可以添加更多过滤规则（如 `.git`、`node_modules`）

#### 4. 目录标记

```go
if info.IsDir() {
	files = append(files, relPath+"/")
} else {
	files = append(files, relPath)
}
```

在目录名后添加 `/`：
- 让 Claude 和用户容易区分文件和目录
- 这是常见的 Unix 约定

#### 5. JSON 返回格式

```go
result, err := json.Marshal(files)
return string(result), nil
```

返回 JSON 数组而不是纯文本：
- 结构化数据更容易解析
- Claude 可以更好地理解和处理
- 便于后续扩展（如添加文件大小、修改时间等）

### 关键代码段分析

#### 可选参数处理

```go
dir := "."
if listFilesInput.Path != "" {
	dir = listFilesInput.Path
}
```

这是处理可选参数的标准模式：
1. 设置默认值
2. 检查参数是否提供
3. 如果提供则使用参数值

#### 错误处理策略

```go
err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
	if err != nil {
		return err  // 传播错误
	}
	// ...
	return nil
})

if err != nil {
	log.Printf("Failed to list files in %s: %v", dir, err)
	return "", err  // 返回错误给 Claude
}
```

多层错误处理：
1. Walk 回调中的错误会停止遍历
2. Walk 返回的错误被记录并返回
3. Claude 会收到错误信息并告知用户

### 为什么这样设计？

**问：为什么返回 JSON 而不是简单的文本列表？**
答：JSON 是结构化的，Claude 可以更准确地解析。如果返回纯文本，Claude 可能会误解格式。

**问：为什么要过滤某些目录？**
答：
- 减少不相关信息
- 提高性能（某些目录可能很大）
- 避免混淆（如 `.git` 目录对用户通常不重要）

**问：为什么使用 filepath.Walk 而不是 os.ReadDir？**
答：`filepath.Walk` 递归遍历所有子目录，而 `os.ReadDir` 只读取一层。对于项目浏览，递归遍历更有用。

**问：可以限制遍历深度吗？**
答：可以。在回调函数中跟踪深度，超过限制时返回 `filepath.SkipDir`。

## 练习建议

1. **添加文件大小信息**：修改返回格式，包含每个文件的大小：
   ```go
   type FileInfo struct {
       Path string `json:"path"`
       Size int64  `json:"size"`
       IsDir bool  `json:"is_dir"`
   }
   ```

2. **添加文件类型过滤**：允许只列出特定类型的文件：
   ```go
   type ListFilesInput struct {
       Path      string `json:"path,omitempty"`
       Extension string `json:"extension,omitempty"`  // 如 ".go"
   }
   ```

3. **限制遍历深度**：添加 `max_depth` 参数，避免遍历过深的目录树

4. **添加排序选项**：按名称、大小或修改时间排序

5. **实现 .gitignore 支持**：读取 .gitignore 文件并跳过匹配的文件

6. **添加文件计数**：返回文件和目录的总数统计

## 常见问题

### Q: 如何处理符号链接？

A: `filepath.Walk` 会跟随符号链接。如果不想跟随，可以检查 `info.Mode()&os.ModeSymlink != 0`。

### Q: 大型目录树会导致性能问题吗？

A: 会的。可以考虑：
- 限制遍历深度
- 添加文件数量限制
- 使用异步遍历
- 缓存结果

### Q: 如何处理权限错误？

A: 当前实现会返回错误。更好的做法是跳过无权限的目录：
```go
if err != nil {
	log.Printf("Skipping %s: %v", path, err)
	return filepath.SkipDir
}
```

### Q: 可以列出隐藏文件吗？

A: 可以。当前实现会列出所有文件。如果要过滤隐藏文件，检查文件名是否以 `.` 开头。

### Q: 如何处理不同操作系统的路径分隔符？

A: `filepath` 包会自动处理。它在 Windows 上使用 `\`，在 Unix 上使用 `/`。

### Q: Claude 如何知道何时使用 list_files 而不是 read_file？

A: Claude 根据：
- 工具描述
- 用户问题
- 上下文

自主判断。如果用户问"有哪些文件"，它会用 `list_files`；如果问"文件内容是什么"，它会用 `read_file`。

## 下一步

很好！现在 Claude 可以浏览文件系统并读取文件了。

在[步骤 4：命令执行](step-4-bash.md)中，我们将添加 `bash` 工具，让 Claude 能够执行 Shell 命令。这将引入新的挑战：安全性和错误处理。

关键概念预告：
- 命令执行的安全考虑
- 标准输出和标准错误的处理
- 命令失败的优雅处理
- 实用工具的组合使用
