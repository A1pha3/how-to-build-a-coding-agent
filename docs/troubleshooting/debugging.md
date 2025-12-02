# 调试技巧

## 简介

本文档介绍如何调试 AI 编程助手工作坊项目中的问题。掌握这些调试技巧可以帮助你快速定位和解决开发过程中遇到的各种问题。

## Verbose 模式

### 启用 Verbose 模式

所有 Go 应用程序都支持 `--verbose` 标志，用于输出详细的执行日志：

```bash
# 基础聊天
go run chat.go --verbose

# 文件读取
go run read.go --verbose

# 目录列表
go run list_files.go --verbose

# 命令执行
go run bash_tool.go --verbose

# 文件编辑
go run edit_tool.go --verbose

# 代码搜索
go run code_search_tool.go --verbose
```

### Verbose 模式输出内容

启用 verbose 模式后，你将看到以下详细信息：

#### 1. API 调用信息

```
2024/01/15 10:30:45 chat.go:89: Making API call to Claude with model: claude-3-7-sonnet-latest
2024/01/15 10:30:47 chat.go:95: API call successful, response received
```

显示内容：
- 使用的模型名称
- API 调用时间
- 调用成功或失败状态

#### 2. 工具执行详情

```
2024/01/15 10:30:48 read.go:45: Tool execution: read_file
2024/01/15 10:30:48 read.go:46: Input: {"path": "main.go"}
2024/01/15 10:30:48 read.go:52: File read successfully, size: 1234 bytes
```

显示内容：
- 调用的工具名称
- 输入参数
- 执行结果（文件大小、行数等）

#### 3. 对话流程

```
2024/01/15 10:30:45 chat.go:65: User input received: "读取 main.go 文件"
2024/01/15 10:30:45 chat.go:70: Sending message to Claude, conversation length: 1
2024/01/15 10:30:47 chat.go:78: Received response from Claude with 2 content blocks
```

显示内容：
- 用户输入内容
- 对话历史长度
- 响应内容块数量

#### 4. 错误详情

```
2024/01/15 10:30:48 read.go:58: Error reading file: open nonexistent.txt: no such file or directory
```

显示内容：
- 错误发生位置（文件名和行号）
- 详细错误信息

### 日志输出位置

- **Verbose 模式**：详细日志输出到 stderr，带时间戳和文件位置
- **普通模式**：仅基本输出到 stdout

```bash
# 将 verbose 日志保存到文件
go run edit_tool.go --verbose 2> debug.log

# 同时查看和保存日志
go run edit_tool.go --verbose 2>&1 | tee debug.log
```


## 日志输出解读

### 日志格式

Verbose 模式的日志格式如下：

```
时间戳 文件名:行号: 日志消息
```

示例：
```
2024/01/15 10:30:45 chat.go:89: Making API call to Claude
```

- `2024/01/15 10:30:45` - 时间戳
- `chat.go:89` - 源文件和行号
- `Making API call to Claude` - 日志消息

### 常见日志消息

#### 会话相关

| 日志消息 | 含义 |
|---------|------|
| `Starting chat session` | 聊天会话开始 |
| `User input received: "..."` | 收到用户输入 |
| `Skipping empty message` | 跳过空消息 |
| `Chat session ended` | 聊天会话结束 |

#### API 相关

| 日志消息 | 含义 |
|---------|------|
| `Anthropic client initialized` | API 客户端初始化完成 |
| `Making API call to Claude` | 正在调用 Claude API |
| `API call successful` | API 调用成功 |
| `API call failed: ...` | API 调用失败 |

#### 工具相关

| 日志消息 | 含义 |
|---------|------|
| `Tool execution: xxx` | 正在执行工具 |
| `Tool result: ...` | 工具执行结果 |
| `Tool error: ...` | 工具执行错误 |

### 日志级别

虽然项目使用简单的日志系统，但可以通过日志内容判断严重程度：

- **信息**：正常操作记录（如 "Starting chat session"）
- **警告**：可能的问题（如 "Skipping empty message"）
- **错误**：需要关注的问题（如 "Error reading file: ..."）

## 调试工具和方法

### 1. 使用 Go 调试器（Delve）

安装 Delve：
```bash
go install github.com/go-delve/delve/cmd/dlv@latest
```

启动调试：
```bash
# 调试运行
dlv debug chat.go

# 设置断点
(dlv) break main.main
(dlv) break chat.go:65

# 运行
(dlv) continue

# 查看变量
(dlv) print conversation
(dlv) print userInput
```

### 2. 添加临时日志

在代码中添加临时日志语句：

```go
import "log"

// 在关键位置添加日志
log.Printf("DEBUG: variable value = %v", variable)
log.Printf("DEBUG: entering function %s", "functionName")
```

### 3. 使用环境变量控制

```bash
# 设置调试环境变量
export DEBUG=true

# 在代码中检查
if os.Getenv("DEBUG") == "true" {
    log.Printf("Debug info: %v", data)
}
```

### 4. 网络调试

检查 API 连接：
```bash
# 测试 API 端点
curl -v https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01"

# 检查 DNS 解析
nslookup api.anthropic.com

# 检查网络延迟
ping api.anthropic.com
```

### 5. 文件系统调试

```bash
# 检查文件是否存在
ls -la path/to/file

# 检查文件内容
cat path/to/file

# 检查文件编码
file path/to/file

# 显示隐藏字符
cat -A path/to/file
```


## 常见调试场景

### 场景 1：API 调用失败

**症状**：程序报错，无法与 Claude 通信

**调试步骤**：

1. 启用 verbose 模式：
```bash
go run chat.go --verbose
```

2. 查看 API 调用日志：
```
2024/01/15 10:30:45 chat.go:89: Making API call to Claude with model: claude-3-7-sonnet-latest
2024/01/15 10:30:47 chat.go:95: API call failed: authentication_error
```

3. 检查 API 密钥：
```bash
echo $ANTHROPIC_API_KEY
```

4. 测试 API 连接：
```bash
curl -v https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-7-sonnet-latest","max_tokens":10,"messages":[{"role":"user","content":"Hi"}]}'
```

### 场景 2：工具执行失败

**症状**：Claude 请求使用工具，但工具执行报错

**调试步骤**：

1. 启用 verbose 模式查看工具调用：
```bash
go run read.go --verbose
```

2. 查看工具执行日志：
```
2024/01/15 10:30:48 read.go:45: Tool execution: read_file
2024/01/15 10:30:48 read.go:46: Input: {"path": "nonexistent.txt"}
2024/01/15 10:30:48 read.go:58: Error reading file: open nonexistent.txt: no such file or directory
```

3. 手动验证操作：
```bash
# 对于文件读取
cat nonexistent.txt

# 对于命令执行
bash -c "your-command"
```

4. 检查权限和路径

### 场景 3：响应异常

**症状**：Claude 的响应不符合预期

**调试步骤**：

1. 启用 verbose 模式查看完整对话：
```bash
go run chat.go --verbose
```

2. 查看对话历史长度：
```
2024/01/15 10:30:45 chat.go:70: Sending message to Claude, conversation length: 5
```

3. 检查响应内容块：
```
2024/01/15 10:30:47 chat.go:78: Received response from Claude with 2 content blocks
```

4. 如果对话过长，考虑清理历史或开始新会话

### 场景 4：性能问题

**症状**：程序响应缓慢

**调试步骤**：

1. 启用 verbose 模式查看时间戳：
```bash
go run edit_tool.go --verbose 2>&1 | ts '[%Y-%m-%d %H:%M:%.S]'
```

2. 分析各阶段耗时：
   - API 调用时间
   - 工具执行时间
   - 网络延迟

3. 检查网络状况：
```bash
time curl -s https://api.anthropic.com > /dev/null
```

4. 优化建议：
   - 减少对话历史长度
   - 简化工具输出
   - 检查网络连接

## 调试最佳实践

### 1. 逐步排查

从最简单的情况开始：

```bash
# 1. 先测试基础聊天
go run chat.go --verbose

# 2. 再测试单个工具
go run read.go --verbose

# 3. 最后测试完整功能
go run edit_tool.go --verbose
```

### 2. 保存日志

将调试日志保存以便分析：

```bash
# 保存所有输出
go run edit_tool.go --verbose 2>&1 | tee debug-$(date +%Y%m%d-%H%M%S).log
```

### 3. 最小化复现

创建最小的测试用例来复现问题：

```bash
# 使用简单的输入测试
echo "Hello" | go run chat.go --verbose
```

### 4. 检查环境一致性

确保开发环境一致：

```bash
# 使用 devenv 确保环境一致
devenv shell
go run chat.go --verbose
```

### 5. 版本信息收集

报告问题时收集版本信息：

```bash
# Go 版本
go version

# 依赖版本
go list -m all

# 系统信息
uname -a
```

## 下一步

- [常见问题](common-issues.md) - 查看常见问题及解决方案
- [错误处理指南](../guides/error-handling.md) - 学习错误处理最佳实践
- [API 参考](../api-reference/agent.md) - 了解 Agent API 详情
