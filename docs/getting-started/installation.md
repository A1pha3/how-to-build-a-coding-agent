# 安装配置

## 简介

本文档将指导你完成项目的安装和配置过程。我们提供两种配置方式：

1. **使用 devenv**（推荐）- 自动配置所有依赖
2. **手动配置** - 使用传统的 Go 开发环境

选择适合你的方式，按照步骤操作即可。

## 前置检查

在开始之前，请确认你已经：

- ✅ 安装了 Go 1.24.2 或更高版本
- ✅ 安装了 Git
- ✅ 获取了 Anthropic API 密钥
- ✅ （推荐）安装了 devenv

如果还没有准备好，请先查看 [前置要求](prerequisites.md) 文档。

## 方案 1：使用 devenv（推荐）

### 为什么选择 devenv？

- ✅ **一键配置**：自动安装所有依赖（Go、Node.js、Python、Rust、ripgrep 等）
- ✅ **环境隔离**：不影响系统环境，多项目互不干扰
- ✅ **跨平台一致**：在 macOS 和 Linux 上行为完全一致
- ✅ **可复现**：团队成员使用相同的开发环境
- ✅ **省时省力**：无需手动安装和配置各种工具

### 步骤 1：安装 Nix

devenv 基于 Nix 包管理器，首先需要安装 Nix：

```bash
# 使用 Determinate Systems 的安装器（推荐）
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**安装完成后**，重启终端或运行：

```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

**验证安装**：

```bash
nix --version
# 应该输出类似：nix (Nix) 2.18.1
```

### 步骤 2：安装 devenv

```bash
nix profile install --accept-flake-config github:cachix/devenv/latest
```

**验证安装**：

```bash
devenv version
# 应该输出 devenv 的版本号
```

### 步骤 3：克隆项目

```bash
# 克隆项目仓库
git clone https://github.com/your-username/ai-coding-agent-workshop.git

# 进入项目目录
cd ai-coding-agent-workshop
```

**注意**：请将 `your-username` 替换为实际的 GitHub 用户名或组织名。

### 步骤 4：配置 API 密钥

在项目根目录创建 `.envrc` 文件（如果不存在）：

```bash
# 创建 .envrc 文件
cat > .envrc << 'EOF'
export ANTHROPIC_API_KEY="your-api-key-here"
EOF
```

**重要**：将 `your-api-key-here` 替换为你的实际 API 密钥。

**安全提示**：

- `.envrc` 文件已在 `.gitignore` 中，不会被提交到仓库
- 不要将 API 密钥硬编码到代码中
- 不要在公开场合分享你的密钥

### 步骤 5：启动开发环境

```bash
# 进入 devenv shell
devenv shell
```

**首次运行**会下载和配置所有依赖，可能需要几分钟时间。

**成功启动后**，你会看到：

```
hello from devenv
Available tools:
git version 2.42.0
go version go1.24.2 darwin/arm64
Python 3.11.6
v20.10.0
Version 5.3.3
rustc 1.75.0
.NET SDK 8.0.100
ripgrep 14.0.3
```

### 步骤 6：下载 Go 依赖

在 devenv shell 中运行：

```bash
go mod download
```

这会下载项目所需的 Go 模块。

### 步骤 7：验证安装

运行第一个示例程序：

```bash
go run chat.go
```

如果看到以下提示，说明安装成功：

```
Chat with Claude (use 'ctrl-c' to quit)
You: 
```

输入 "Hello!" 测试对话功能。

### devenv 常用命令

```bash
# 进入开发环境
devenv shell

# 运行测试
devenv test

# 查看环境信息
devenv info

# 更新 devenv
devenv update

# 退出开发环境
exit
```

## 方案 2：手动配置

### 适用场景

- 你已经有完整的 Go 开发环境
- 不想使用 Nix/devenv
- 只需要运行部分功能（前 5 个步骤不需要 ripgrep）

### 步骤 1：验证 Go 安装

```bash
go version
# 应该输出 go1.24.2 或更高版本
```

如果未安装，请参考 [前置要求](prerequisites.md) 文档。

### 步骤 2：克隆项目

```bash
# 克隆项目仓库
git clone https://github.com/your-username/ai-coding-agent-workshop.git

# 进入项目目录
cd ai-coding-agent-workshop
```

### 步骤 3：下载依赖

```bash
# 下载并安装 Go 模块依赖
go mod tidy
```

这会下载以下依赖：

- `github.com/anthropics/anthropic-sdk-go` - Anthropic SDK
- `github.com/invopop/jsonschema` - JSON Schema 生成
- 其他传递依赖

**验证依赖**：

```bash
go mod verify
# 应该输出：all modules verified
```

### 步骤 4：配置 API 密钥

选择以下任一方式配置 API 密钥：

**方式 A：环境变量（推荐）**

```bash
# 临时设置（当前终端会话）
export ANTHROPIC_API_KEY="your-api-key-here"

# 永久设置（添加到 shell 配置文件）
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc  # 或 ~/.zshrc
```

**方式 B：.envrc 文件**

在项目根目录创建 `.envrc` 文件：

```bash
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' > .envrc
source .envrc
```

**验证配置**：

```bash
echo $ANTHROPIC_API_KEY
# 应该输出你的 API 密钥
```

### 步骤 5：安装 ripgrep（可选）

ripgrep 只在步骤 6（`code_search_tool.go`）中需要。

**macOS**：

```bash
brew install ripgrep
```

**Linux**：

```bash
# Ubuntu/Debian
sudo apt install ripgrep

# Fedora
sudo dnf install ripgrep
```

**验证安装**：

```bash
rg --version
# 应该输出 ripgrep 的版本号
```

### 步骤 6：验证安装

运行第一个示例程序：

```bash
go run chat.go
```

如果看到聊天提示符，说明安装成功。


## 环境验证

### 完整验证脚本

创建一个验证脚本来检查所有配置：

```bash
#!/bin/bash

echo "========================================="
echo "环境验证脚本"
echo "========================================="
echo ""

# 检查 Go
echo "1. 检查 Go..."
if command -v go &> /dev/null; then
    go version
    echo "✅ Go 已安装"
else
    echo "❌ Go 未安装"
    exit 1
fi
echo ""

# 检查 Git
echo "2. 检查 Git..."
if command -v git &> /dev/null; then
    git --version
    echo "✅ Git 已安装"
else
    echo "❌ Git 未安装"
    exit 1
fi
echo ""

# 检查 API 密钥
echo "3. 检查 API 密钥..."
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ ANTHROPIC_API_KEY 未设置"
    echo "请运行: export ANTHROPIC_API_KEY='your-api-key-here'"
    exit 1
else
    echo "✅ ANTHROPIC_API_KEY 已设置"
    echo "密钥长度: ${#ANTHROPIC_API_KEY} 字符"
fi
echo ""

# 检查 Go 模块
echo "4. 检查 Go 模块..."
if [ -f "go.mod" ]; then
    echo "✅ go.mod 存在"
    go mod verify
    if [ $? -eq 0 ]; then
        echo "✅ 所有模块已验证"
    else
        echo "❌ 模块验证失败，请运行: go mod tidy"
        exit 1
    fi
else
    echo "❌ go.mod 不存在，请确认在项目根目录"
    exit 1
fi
echo ""

# 检查 ripgrep（可选）
echo "5. 检查 ripgrep（可选）..."
if command -v rg &> /dev/null; then
    rg --version | head -n 1
    echo "✅ ripgrep 已安装（步骤 6 可用）"
else
    echo "⚠️  ripgrep 未安装（步骤 6 需要）"
fi
echo ""

# 检查 devenv（可选）
echo "6. 检查 devenv（可选）..."
if command -v devenv &> /dev/null; then
    devenv version
    echo "✅ devenv 已安装"
else
    echo "⚠️  devenv 未安装（推荐安装）"
fi
echo ""

echo "========================================="
echo "验证完成！"
echo "========================================="
echo ""
echo "下一步："
echo "  运行: go run chat.go"
echo "  或查看: docs/getting-started/quick-start.md"
```

**运行验证**：

```bash
chmod +x verify.sh
./verify.sh
```

### 手动验证步骤

如果不想使用脚本，可以手动验证：

**1. 验证 Go 环境**

```bash
go version
go env GOPATH
go env GOROOT
```

**2. 验证项目结构**

```bash
ls -la
# 应该看到：chat.go, read.go, go.mod 等文件
```

**3. 验证依赖**

```bash
go list -m all
# 应该列出所有依赖模块
```

**4. 验证 API 密钥**

```bash
echo $ANTHROPIC_API_KEY | wc -c
# 应该输出一个大于 50 的数字（密钥长度）
```

**5. 编译测试**

```bash
go build chat.go
./chat
# 应该能正常启动
```

## 项目结构说明

安装完成后，项目目录结构如下：

```
ai-coding-agent-workshop/
├── .envrc                  # 环境变量配置（需要创建）
├── .gitignore              # Git 忽略文件
├── AGENT.md                # 开发环境说明
├── README.md               # 英文文档
├── Makefile                # 构建脚本
├── devenv.nix              # devenv 配置
├── devenv.yaml             # devenv 设置
├── devenv.lock             # devenv 锁定文件
├── go.mod                  # Go 模块定义
├── go.sum                  # 依赖锁定文件
├── chat.go                 # 步骤 1：基础聊天
├── read.go                 # 步骤 2：文件读取
├── list_files.go           # 步骤 3：目录列表
├── bash_tool.go            # 步骤 4：命令执行
├── edit_tool.go            # 步骤 5：文件编辑
├── code_search_tool.go     # 步骤 6：代码搜索
├── docs/                   # 中文文档
│   ├── README.md
│   ├── getting-started/
│   ├── architecture/
│   ├── workshop/
│   ├── api-reference/
│   ├── guides/
│   └── troubleshooting/
├── prompts/                # 示例提示词
│   ├── 00-weather.md
│   ├── 01-read_file.md
│   ├── 02-list_files.md
│   ├── 03-bash_tool.md
│   └── 04-edit_tool.md
├── fizzbuzz.js             # 示例文件
└── riddle.txt              # 示例文件
```

### 重要文件说明

- **chat.go** - 最基础的聊天程序，是学习的起点
- **go.mod** - 定义项目依赖，不要手动修改
- **devenv.nix** - devenv 配置，定义开发环境
- **.envrc** - 环境变量配置，需要自己创建
- **docs/** - 完整的中文文档

## 配置优化

### Go 模块代理（可选）

如果下载依赖很慢，可以配置国内镜像：

```bash
# 使用七牛云镜像
export GOPROXY=https://goproxy.cn,direct

# 或使用阿里云镜像
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct

# 永久配置
go env -w GOPROXY=https://goproxy.cn,direct
```

### 编辑器配置

**VS Code 配置**（`.vscode/settings.json`）：

```json
{
  "go.useLanguageServer": true,
  "go.toolsManagement.autoUpdate": true,
  "go.lintTool": "golangci-lint",
  "go.lintOnSave": "package",
  "editor.formatOnSave": true,
  "[go]": {
    "editor.defaultFormatter": "golang.go"
  }
}
```

**GoLand 配置**：

1. 打开 Settings → Go → GOROOT
2. 确认 GOROOT 指向正确的 Go 安装路径
3. 打开 Settings → Go → Go Modules
4. 启用 "Enable Go modules integration"

### 性能优化

**加速 Go 编译**：

```bash
# 启用编译缓存
export GOCACHE=$(go env GOCACHE)

# 增加并行编译数
export GOMAXPROCS=$(nproc)
```

**减少 devenv 启动时间**：

```bash
# 使用 direnv 自动加载环境
# 安装 direnv
brew install direnv  # macOS
sudo apt install direnv  # Linux

# 配置 shell
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
# 或
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc

# 允许 .envrc
direnv allow
```

## 常见问题

### Q: go mod tidy 失败怎么办？

**A**: 可能的原因和解决方法：

1. **网络问题**：
   ```bash
   # 配置代理
   export GOPROXY=https://goproxy.cn,direct
   go mod tidy
   ```

2. **权限问题**：
   ```bash
   # 检查 GOPATH 权限
   ls -la $(go env GOPATH)
   # 如果需要，修改权限
   chmod -R u+w $(go env GOPATH)
   ```

3. **缓存问题**：
   ```bash
   # 清理缓存
   go clean -modcache
   go mod tidy
   ```

### Q: API 密钥配置后仍然提示未设置？

**A**: 检查以下几点：

1. **确认环境变量已导出**：
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

2. **检查 shell 配置文件**：
   ```bash
   # 确认添加到了正确的文件
   cat ~/.bashrc | grep ANTHROPIC
   # 或
   cat ~/.zshrc | grep ANTHROPIC
   ```

3. **重新加载配置**：
   ```bash
   source ~/.bashrc  # 或 ~/.zshrc
   ```

4. **在 devenv 中**：
   ```bash
   # 确保 .envrc 文件存在且正确
   cat .envrc
   # 重新进入 devenv shell
   exit
   devenv shell
   ```

### Q: devenv shell 启动很慢？

**A**: 首次启动需要下载大量依赖，这是正常的。后续启动会快很多。

**加速方法**：

1. **使用 direnv**（见上文"性能优化"）
2. **使用 cachix**：
   ```bash
   nix-env -iA cachix -f https://cachix.org/api/v1/install
   cachix use devenv
   ```

### Q: 在 Windows 上如何安装？

**A**: 推荐使用 WSL2：

1. 安装 WSL2：
   ```powershell
   wsl --install
   ```

2. 在 WSL2 中按照 Linux 的步骤操作

3. 或者使用原生 Windows 环境（不支持 devenv）：
   - 安装 Go for Windows
   - 使用 PowerShell 或 Git Bash
   - 手动配置环境变量

### Q: 如何更新项目？

**A**: 

```bash
# 拉取最新代码
git pull origin main

# 更新依赖
go mod tidy

# 如果使用 devenv
devenv update
```

### Q: 如何卸载？

**A**: 

**手动配置方式**：

```bash
# 删除项目目录
rm -rf ai-coding-agent-workshop

# 清理 Go 缓存（可选）
go clean -modcache
```

**devenv 方式**：

```bash
# 删除项目目录
rm -rf ai-coding-agent-workshop

# 卸载 devenv（可选）
nix profile remove devenv

# 卸载 Nix（可选）
/nix/nix-installer uninstall
```

## 下一步

安装配置完成后，你可以：

1. **[快速开始](quick-start.md)** - 运行第一个示例
2. **[工作坊教程](../workshop/)** - 深入学习每个步骤
3. **[架构设计](../architecture/overview.md)** - 理解系统设计

## 获取帮助

如果遇到问题：

- 查看 **[故障排查](../troubleshooting/common-issues.md)**
- 查看 **[调试技巧](../troubleshooting/debugging.md)**
- 在 GitHub 上提交 Issue
- 加入社区讨论

---

**提示**：建议先完成环境验证，确保所有配置正确，再继续后续步骤。使用 `--verbose` 参数可以查看详细的执行日志，有助于排查问题。
