# 步骤 5：文件编辑

## 学习目标

- 理解文件编辑工具的实现策略
- 掌握字符串查找和替换的方法
- 学习文件创建和目录管理
- 了解编辑操作的验证机制
- 认识原子性操作的重要性

## 背景知识

到目前为止，Claude 可以读取文件、列出目录、执行命令，但还不能修改文件。在这一步中，我们将添加 `edit_file` 工具，让 Claude 能够编辑文件内容。

### 编辑策略

有多种方式实现文件编辑：

1. **完全替换**：提供新的完整文件内容
   - 优点：简单直接
   - 缺点：对大文件效率低，容易出错

2. **行号编辑**：指定行号和新内容
   - 优点：精确
   - 缺点：行号可能变化，难以维护

3. **字符串替换**：查找旧字符串，替换为新字符串
   - 优点：直观，不依赖行号
   - 缺点：需要确保匹配唯一性

我们选择**字符串替换**策略，因为它最符合人类的编辑思维。

### 设计原则

1. **唯一性**：`old_str` 必须在文件中唯一出现
2. **明确性**：`old_str` 和 `new_str` 必须不同
3. **安全性**：创建文件时自动创建目录
4. **灵活性**：支持文件创建和内容追加

## 实现步骤

### 1. 新增导入

```go
import (
	// ... 之前的导入 ...
	"path"
)
```

- `path`：路径操作（注意与 `path/filepath` 的区别）

### 2. EditFile 工具定义

```go
var EditFileDefinition = ToolDefinition{
	Name: "edit_file",
	Description: `Make edits to a text file.

Replaces 'old_str' with 'new_str' in the given file. 'old_str' and 'new_str' MUST be different from each other.

If the file specified with path doesn't exist, it will be created.
`,
	InputSchema: EditFileInputSchema,
	Function:    EditFile,
}
```

**Description 要点**：
- 清楚说明替换机制
- 强调 `old_str` 和 `new_str` 必须不同
- 说明文件不存在时的行为

### 3. 输入参数定义

```go
type EditFileInput struct {
	Path   string `json:"path" jsonschema_description:"The path to the file"`
	OldStr string `json:"old_str" jsonschema_description:"Text to search for - must match exactly and must only have one match exactly"`
	NewStr string `json:"new_str" jsonschema_description:"Text to replace old_str with"`
}

var EditFileInputSchema = GenerateSchema[EditFileInput]()
```

**参数说明**：
- `Path`：文件路径
- `OldStr`：要查找的字符串（必须精确匹配且唯一）
- `NewStr`：替换后的字符串

### 4. EditFile 工具实现

```go
func EditFile(input json.RawMessage) (string, error) {
	editFileInput := EditFileInput{}
	err := json.Unmarshal(input, &editFileInput)
	if err != nil {
		return "", err
	}

	// 验证输入
	if editFileInput.Path == "" || editFileInput.OldStr == editFileInput.NewStr {
		log.Printf("EditFile failed: invalid input parameters")
		return "", fmt.Errorf("invalid input parameters")
	}

	log.Printf("Editing file: %s (replacing %d chars with %d chars)", 
		editFileInput.Path, len(editFileInput.OldStr), len(editFileInput.NewStr))
	
	// 读取文件
	content, err := os.ReadFile(editFileInput.Path)
	if err != nil {
		// 特殊情况：文件不存在且 old_str 为空 = 创建新文件
		if os.IsNotExist(err) && editFileInput.OldStr == "" {
			log.Printf("File does not exist, creating new file: %s", editFileInput.Path)
			return createNewFile(editFileInput.Path, editFileInput.NewStr)
		}
		log.Printf("Failed to read file %s: %v", editFileInput.Path, err)
		return "", err
	}

	oldContent := string(content)

	// 特殊情况：old_str 为空 = 追加内容
	var newContent string
	if editFileInput.OldStr == "" {
		newContent = oldContent + editFileInput.NewStr
	} else {
		// 检查匹配次数
		count := strings.Count(oldContent, editFileInput.OldStr)
		if count == 0 {
			log.Printf("EditFile failed: old_str not found in file %s", editFileInput.Path)
			return "", fmt.Errorf("old_str not found in file")
		}
		if count > 1 {
			log.Printf("EditFile failed: old_str found %d times in file %s, must be unique", 
				count, editFileInput.Path)
			return "", fmt.Errorf("old_str found %d times in file, must be unique", count)
		}

		// 执行替换
		newContent = strings.Replace(oldContent, editFileInput.OldStr, editFileInput.NewStr, 1)
	}

	// 写入文件
	err = os.WriteFile(editFileInput.Path, []byte(newContent), 0644)
	if err != nil {
		log.Printf("Failed to write file %s: %v", editFileInput.Path, err)
		return "", err
	}

	log.Printf("Successfully edited file %s", editFileInput.Path)
	return "OK", nil
}
```


### 5. 文件创建辅助函数

```go
func createNewFile(filePath, content string) (string, error) {
	log.Printf("Creating new file: %s (%d bytes)", filePath, len(content))
	
	// 获取目录路径
	dir := path.Dir(filePath)
	if dir != "." {
		log.Printf("Creating directory: %s", dir)
		// 递归创建目录
		err := os.MkdirAll(dir, 0755)
		if err != nil {
			log.Printf("Failed to create directory %s: %v", dir, err)
			return "", fmt.Errorf("failed to create directory: %w", err)
		}
	}

	// 创建文件
	err := os.WriteFile(filePath, []byte(content), 0644)
	if err != nil {
		log.Printf("Failed to create file %s: %v", filePath, err)
		return "", fmt.Errorf("failed to create file: %w", err)
	}

	log.Printf("Successfully created file %s", filePath)
	return fmt.Sprintf("Successfully created file %s", filePath), nil
}
```

**关键点**：
- 使用 `os.MkdirAll` 递归创建目录
- 权限 `0755` 允许所有者读写执行，其他人读执行
- 文件权限 `0644` 允许所有者读写，其他人只读

### 6. 注册工具

```go
func main() {
	// ... 之前的代码 ...

	tools := []ToolDefinition{
		ReadFileDefinition, 
		ListFilesDefinition, 
		BashDefinition,
		EditFileDefinition,
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

## 运行和测试

### 编译和运行

```bash
# 基本运行
go run edit_tool.go

# 启用详细日志
go run edit_tool.go --verbose
```

### 示例对话 1：修改文件内容

```
Chat with Claude (use 'ctrl-c' to quit)
You: 请在 README.md 中把 "Workshop" 改为 "工作坊"
tool: read_file({"path":"README.md"})
result: # AI Programming Assistant Workshop
...
tool: edit_file({"path":"README.md","old_str":"Workshop","new_str":"工作坊"})
result: OK
Claude: 已成功将 README.md 中的 "Workshop" 修改为 "工作坊"。
```

### 示例对话 2：创建新文件

```
You: 创建一个新文件 notes.txt，内容是 "这是我的笔记"
tool: edit_file({"path":"notes.txt","old_str":"","new_str":"这是我的笔记"})
result: Successfully created file notes.txt
Claude: 已成功创建文件 notes.txt，内容为 "这是我的笔记"。
```

### 示例对话 3：追加内容

```
You: 在 notes.txt 末尾添加一行 "第二条笔记"
tool: read_file({"path":"notes.txt"})
result: 这是我的笔记
tool: edit_file({"path":"notes.txt","old_str":"","new_str":"\n第二条笔记"})
result: OK
Claude: 已在 notes.txt 末尾添加 "第二条笔记"。
```

### 示例对话 4：处理编辑错误

```
You: 把 README.md 中的 "test" 改为 "测试"
tool: read_file({"path":"README.md"})
result: # AI Programming Assistant 工作坊
...
tool: edit_file({"path":"README.md","old_str":"test","new_str":"测试"})
result: 
error: old_str not found in file
Claude: 抱歉，在 README.md 中没有找到 "test" 这个词。请确认要修改的内容是否存在。
```

### 示例对话 5：创建带目录的文件

```
You: 创建文件 docs/new/guide.md，内容是 "# 新指南"
tool: edit_file({"path":"docs/new/guide.md","old_str":"","new_str":"# 新指南"})
result: Successfully created file docs/new/guide.md
Claude: 已成功创建文件 docs/new/guide.md（包括必要的目录）。
```

## 代码解析

### 核心概念

#### 1. 字符串替换验证

```go
count := strings.Count(oldContent, editFileInput.OldStr)
if count == 0 {
	return "", fmt.Errorf("old_str not found in file")
}
if count > 1 {
	return "", fmt.Errorf("old_str found %d times in file, must be unique", count)
}
```

**为什么需要唯一性？**
- 避免意外修改多处
- 确保编辑的精确性
- 如果有多处匹配，Claude 应该提供更具体的 `old_str`

#### 2. 特殊情况处理

```go
if editFileInput.OldStr == "" {
	// 情况1：文件不存在 → 创建文件
	// 情况2：文件存在 → 追加内容
}
```

这个设计允许：
- 创建新文件：`old_str=""`, 文件不存在
- 追加内容：`old_str=""`, 文件存在

#### 3. 目录自动创建

```go
dir := path.Dir(filePath)
if dir != "." {
	err := os.MkdirAll(dir, 0755)
}
```

`os.MkdirAll` 的特点：
- 递归创建所有必要的父目录
- 如果目录已存在，不会报错
- 类似于 `mkdir -p` 命令

#### 4. 文件权限

```go
os.WriteFile(filePath, []byte(content), 0644)
```

权限 `0644` 的含义：
- `6` (110)：所有者可读写
- `4` (100)：组可读
- `4` (100)：其他人可读

这是文本文件的标准权限。

### 关键代码段分析

#### 输入验证

```go
if editFileInput.Path == "" || editFileInput.OldStr == editFileInput.NewStr {
	return "", fmt.Errorf("invalid input parameters")
}
```

防止无意义的操作：
- 空路径
- 新旧字符串相同（没有实际修改）

#### 错误处理分层

```go
content, err := os.ReadFile(editFileInput.Path)
if err != nil {
	if os.IsNotExist(err) && editFileInput.OldStr == "" {
		return createNewFile(editFileInput.Path, editFileInput.NewStr)
	}
	return "", err
}
```

区分不同类型的错误：
- 文件不存在 + `old_str` 为空 → 创建文件
- 文件不存在 + `old_str` 不为空 → 返回错误
- 其他错误 → 返回错误

#### 原子性考虑

```go
err = os.WriteFile(editFileInput.Path, []byte(newContent), 0644)
```

`os.WriteFile` 的行为：
- 创建临时文件
- 写入内容
- 原子性地重命名（在大多数系统上）

但这不是完全原子的。更安全的做法：
```go
tmpFile := filePath + ".tmp"
os.WriteFile(tmpFile, content, 0644)
os.Rename(tmpFile, filePath)
```

### 为什么这样设计？

**问：为什么不使用行号编辑？**
答：
- 行号在文件修改后会变化
- 需要先读取文件才能知道行号
- 字符串替换更直观

**问：为什么限制 `old_str` 必须唯一？**
答：
- 防止意外修改
- 如果有多处匹配，说明 `old_str` 不够具体
- Claude 可以提供更长的上下文作为 `old_str`

**问：为什么允许 `old_str` 为空？**
答：
- 支持文件创建
- 支持内容追加
- 提供更灵活的使用方式

**问：如何处理大文件？**
答：当前实现将整个文件读入内存。对于大文件，应该：
- 流式处理
- 使用临时文件
- 限制文件大小

## 安全考虑

### 潜在风险

1. **路径遍历攻击**
   ```go
   path: "../../etc/passwd"  // 访问系统文件
   ```

2. **覆盖重要文件**
   ```go
   path: "go.mod"  // 破坏项目配置
   ```

3. **磁盘空间耗尽**
   ```go
   new_str: "x" * 1000000000  // 创建巨大文件
   ```

### 缓解措施

1. **路径验证**
   ```go
   // 确保路径在工作目录内
   absPath, _ := filepath.Abs(editFileInput.Path)
   workDir, _ := os.Getwd()
   if !strings.HasPrefix(absPath, workDir) {
       return "", fmt.Errorf("path outside working directory")
   }
   ```

2. **文件白名单**
   ```go
   // 只允许编辑特定类型的文件
   allowedExtensions := []string{".txt", ".md", ".go"}
   ```

3. **大小限制**
   ```go
   if len(editFileInput.NewStr) > 1024*1024 {  // 1MB
       return "", fmt.Errorf("content too large")
   }
   ```

4. **备份机制**
   ```go
   // 编辑前创建备份
   backupPath := filePath + ".backup"
   os.WriteFile(backupPath, content, 0644)
   ```

## 练习建议

1. **添加备份功能**：编辑前自动创建 `.backup` 文件

2. **实现撤销功能**：保存编辑历史，允许回滚

3. **添加多处替换**：允许 `old_str` 有多个匹配，全部替换

4. **实现正则表达式替换**：支持更复杂的模式匹配

5. **添加差异预览**：在实际修改前显示将要进行的更改

6. **实现行范围编辑**：支持 "替换第 10-20 行" 这样的操作

## 常见问题

### Q: 如何处理二进制文件？

A: 当前实现只适合文本文件。对于二进制文件：
- 检测文件类型
- 拒绝编辑二进制文件
- 或使用专门的二进制编辑工具

### Q: 如何处理文件编码？

A: 当前假设 UTF-8 编码。对于其他编码：
- 检测文件编码
- 转换为 UTF-8 处理
- 转换回原编码保存

### Q: 多个 Claude 实例同时编辑同一文件会怎样？

A: 会有竞态条件。解决方案：
- 文件锁
- 版本控制
- 冲突检测和解决

### Q: 如何处理很长的 `old_str`？

A: 没有限制。但实践中：
- Claude 会选择足够长以确保唯一性
- 但不会过长以避免浪费 tokens

### Q: 可以一次编辑多个文件吗？

A: 当前不支持。Claude 需要多次调用工具。可以实现批量编辑工具。

### Q: 如何验证编辑是否成功？

A: Claude 通常会：
1. 调用 `edit_file`
2. 调用 `read_file` 验证结果
3. 向用户确认

## 下一步

出色！现在 Claude 可以修改文件了，这使它成为一个真正的编程助手。

在[步骤 6：代码搜索](step-6-search.md)中，我们将添加 `code_search` 工具，集成 ripgrep 进行快速代码搜索。这将展示如何集成外部工具和处理复杂的搜索结果。

关键概念预告：
- 外部工具集成（ripgrep）
- 搜索参数和选项
- 结果格式化和限制
- 正则表达式支持
