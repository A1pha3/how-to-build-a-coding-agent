# 常见问题

## 简介

本文档列出了使用 AI 编程助手工作坊项目时可能遇到的常见问题及其解决方案。问题按类别组织，包括 API 错误、环境问题和依赖问题。

## 问题检查清单

在深入排查具体问题之前，请先完成以下基础检查：

### 快速检查清单

- [ ] **API 密钥**：`ANTHROPIC_API_KEY` 环境变量已设置
- [ ] **Go 版本**：Go 1.24.2 或更高版本已安装
- [ ] **依赖安装**：已运行 `go mod tidy`
- [ ] **网络连接**：可以访问 Anthropic API 服务
- [ ] **文件权限**：对工作目录有读写权限

### 验证命令

```bash
# 检查 API 密钥
echo $ANTHROPIC_API_KEY

# 检查 Go 版本
go version

# 检查依赖状态
go mod verify

# 测试网络连接
curl -I https://api.anthropic.com
```

## API 错误

### 1. 认证失败（401 Unauthorized）

**错误信息**：
```
Error: authentication_error: invalid x-api-key
```

**原因**：
- API 密钥未设置或设置错误
- API 密钥已过期或被撤销
- 环境变量未正确导出

**解决方案**：

1. 确认 API 密钥已设置：
```bash
echo $ANTHROPIC_API_KEY
```

2. 如果为空，设置 API 密钥：
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

3. 验证密钥格式（应以 `sk-ant-` 开头）

4. 如果使用 devenv，确保在 `.envrc` 中配置：
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

5. 在 [Anthropic Console](https://console.anthropic.com/) 检查密钥状态

### 2. 配额超限（429 Too Many Requests）

**错误信息**：
```
Error: rate_limit_error: rate limit exceeded
```

**原因**：
- 请求频率过高
- 账户配额已用完
- 并发请求过多

**解决方案**：

1. 等待一段时间后重试（通常 1-5 分钟）

2. 检查 [Anthropic Dashboard](https://console.anthropic.com/) 的使用量

3. 如果是开发测试，考虑：
   - 减少请求频率
   - 使用更短的对话
   - 清理不必要的对话历史

4. 如需更高配额，联系 Anthropic 升级账户

### 3. 请求超时

**错误信息**：
```
Error: context deadline exceeded
```

**原因**：
- 网络连接不稳定
- 请求内容过长
- API 服务响应慢

**解决方案**：

1. 检查网络连接：
```bash
ping api.anthropic.com
```

2. 减少单次请求的内容长度

3. 如果使用代理，检查代理配置：
```bash
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

4. 尝试增加超时时间（需修改代码）

### 4. 无效请求（400 Bad Request）

**错误信息**：
```
Error: invalid_request_error: messages: ...
```

**原因**：
- 消息格式不正确
- 参数值超出范围
- 缺少必需参数

**解决方案**：

1. 使用 `--verbose` 模式查看详细请求：
```bash
go run chat.go --verbose
```

2. 检查消息内容是否为空

3. 确保对话历史格式正确

4. 验证 `MaxTokens` 参数在有效范围内


## 环境问题

### 1. Go 未安装或版本过低

**错误信息**：
```
go: command not found
```
或
```
go: go.mod requires go >= 1.24.2
```

**解决方案**：

1. 检查 Go 是否安装：
```bash
go version
```

2. 如果未安装，使用 devenv（推荐）：
```bash
devenv shell
```

3. 或手动安装 Go 1.24.2+：
   - macOS: `brew install go`
   - Linux: 从 [golang.org](https://golang.org/dl/) 下载
   - Windows: 使用官方安装程序

4. 验证安装：
```bash
go version
# 应显示: go version go1.24.2 或更高
```

### 2. devenv 环境问题

**错误信息**：
```
devenv: command not found
```
或
```
error: experimental Nix feature 'nix-command' is disabled
```

**解决方案**：

1. 安装 devenv：
```bash
# 使用官方安装脚本
curl -fsSL https://devenv.sh/install.sh | bash
```

2. 启用 Nix 实验性功能，编辑 `~/.config/nix/nix.conf`：
```
experimental-features = nix-command flakes
```

3. 重新进入 devenv 环境：
```bash
devenv shell
```

4. 如果问题持续，尝试清理缓存：
```bash
devenv gc
devenv shell
```

### 3. 环境变量未生效

**问题描述**：
设置了 `ANTHROPIC_API_KEY` 但程序仍报错

**原因**：
- 环境变量只在当前终端会话有效
- 使用了不同的 shell
- `.envrc` 未被 direnv 加载

**解决方案**：

1. 确认当前 shell 中的变量：
```bash
echo $ANTHROPIC_API_KEY
```

2. 永久设置（添加到 shell 配置文件）：
```bash
# Bash (~/.bashrc)
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.bashrc
source ~/.bashrc

# Zsh (~/.zshrc)
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc
```

3. 如果使用 direnv，确保已允许：
```bash
direnv allow
```

### 4. 文件权限问题

**错误信息**：
```
permission denied
```

**解决方案**：

1. 检查文件权限：
```bash
ls -la
```

2. 修复权限：
```bash
chmod +x *.go
chmod -R u+rw .
```

3. 如果是系统目录，使用 sudo（谨慎）：
```bash
sudo chown -R $USER:$USER .
```

### 5. ripgrep 未安装

**错误信息**：
```
exec: "rg": executable file not found in $PATH
```

**原因**：
代码搜索工具需要 ripgrep

**解决方案**：

1. 使用 devenv（自动包含 ripgrep）：
```bash
devenv shell
```

2. 或手动安装：
```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
sudo apt install ripgrep

# Arch Linux
sudo pacman -S ripgrep
```

3. 验证安装：
```bash
rg --version
```


## 依赖问题

### 1. Go 模块下载失败

**错误信息**：
```
go: downloading github.com/anthropics/anthropic-sdk-go ...
go: github.com/anthropics/anthropic-sdk-go: module lookup disabled
```

**解决方案**：

1. 确保 Go 模块已启用：
```bash
export GO111MODULE=on
```

2. 清理模块缓存并重新下载：
```bash
go clean -modcache
go mod tidy
```

3. 如果在中国大陆，设置代理：
```bash
export GOPROXY=https://goproxy.cn,direct
go mod tidy
```

4. 验证依赖：
```bash
go mod verify
```

### 2. 依赖版本冲突

**错误信息**：
```
go: inconsistent vendoring
```
或
```
require ... but ... is required
```

**解决方案**：

1. 更新依赖到最新兼容版本：
```bash
go get -u ./...
go mod tidy
```

2. 如果有 vendor 目录，重新生成：
```bash
rm -rf vendor
go mod vendor
```

3. 检查 `go.mod` 文件中的版本要求

4. 如果问题持续，尝试清理并重建：
```bash
rm go.sum
go mod tidy
```

### 3. 缺少依赖包

**错误信息**：
```
cannot find package "github.com/xxx/xxx"
```

**解决方案**：

1. 下载缺失的依赖：
```bash
go mod tidy
```

2. 如果是特定包，手动获取：
```bash
go get github.com/anthropics/anthropic-sdk-go
go get github.com/invopop/jsonschema
```

3. 验证所有依赖已安装：
```bash
go mod download
```

### 4. 编译错误

**错误信息**：
```
undefined: xxx
```
或
```
cannot use xxx as type yyy
```

**解决方案**：

1. 确保使用正确的 Go 版本：
```bash
go version
# 需要 Go 1.24.2+
```

2. 检查是否有语法错误：
```bash
go build ./...
```

3. 运行代码格式化：
```bash
go fmt ./...
```

4. 检查导入语句是否正确

## 工具执行问题

### 1. 文件读取失败

**错误信息**：
```
Error reading file: open xxx: no such file or directory
```

**解决方案**：

1. 确认文件路径正确：
```bash
ls -la path/to/file
```

2. 使用相对路径或绝对路径

3. 检查文件是否存在且可读

4. 使用 `--verbose` 查看详细信息：
```bash
go run read.go --verbose
```

### 2. 命令执行失败

**错误信息**：
```
Error executing command: exit status 1
```

**解决方案**：

1. 手动测试命令是否可执行：
```bash
# 直接在终端运行相同命令
```

2. 检查命令是否存在：
```bash
which <command>
```

3. 查看详细错误输出：
```bash
go run bash_tool.go --verbose
```

4. 确保命令在 PATH 中

### 3. 文件编辑失败

**错误信息**：
```
Error: old_str not found in file
```

**解决方案**：

1. 确认要替换的字符串完全匹配（包括空格和换行）

2. 先读取文件内容确认：
```bash
cat -A filename  # 显示所有字符包括不可见字符
```

3. 检查文件编码是否为 UTF-8

4. 使用 `--verbose` 查看详细操作

## 获取帮助

如果以上解决方案都无法解决你的问题：

### 1. 查看详细日志

使用 `--verbose` 标志获取详细的执行日志：

```bash
go run edit_tool.go --verbose
```

### 2. 检查项目文档

- [调试技巧](debugging.md) - 详细的调试方法
- [错误处理指南](../guides/error-handling.md) - 错误处理最佳实践
- [API 参考](../api-reference/) - 详细的 API 文档

### 3. 社区支持

- 在项目仓库提交 Issue
- 查看已有的 Issue 和讨论
- 参考 [Anthropic 官方文档](https://docs.anthropic.com/)

## 下一步

- [调试技巧](debugging.md) - 学习更多调试方法
- [错误处理指南](../guides/error-handling.md) - 了解错误处理最佳实践
- [快速开始](../getting-started/quick-start.md) - 重新开始项目配置
