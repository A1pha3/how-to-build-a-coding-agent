# 前置要求

## 简介

在开始构建 AI 编程助手之前，你需要准备好开发环境和必要的工具。本文档将帮助你检查和安装所有必需的软件依赖。

## 必需软件

### 1. Go 编程语言

**版本要求**：Go 1.24.2 或更高版本

**检查是否已安装**：

```bash
go version
```

预期输出类似：
```
go version go1.24.2 darwin/arm64
```

**安装方法**：

- **macOS**：
  ```bash
  # 使用 Homebrew
  brew install go
  
  # 或从官网下载
  # https://go.dev/dl/
  ```

- **Linux**：
  ```bash
  # Ubuntu/Debian
  sudo apt update
  sudo apt install golang-go
  
  # 或从官网下载
  wget https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  ```

- **Windows**：
  - 从 [官网](https://go.dev/dl/) 下载安装程序
  - 运行 `.msi` 文件并按照提示安装

**验证安装**：

```bash
go version
go env GOPATH
```

### 2. Git 版本控制

**版本要求**：Git 2.0 或更高版本

**检查是否已安装**：

```bash
git --version
```

**安装方法**：

- **macOS**：
  ```bash
  brew install git
  ```

- **Linux**：
  ```bash
  sudo apt install git  # Ubuntu/Debian
  sudo yum install git  # CentOS/RHEL
  ```

- **Windows**：
  - 从 [git-scm.com](https://git-scm.com/) 下载安装

### 3. Anthropic API 密钥

**获取方法**：

1. 访问 [Anthropic Console](https://console.anthropic.com/)
2. 注册或登录账号
3. 进入 API Keys 页面
4. 点击 "Create Key" 创建新密钥
5. 复制并妥善保存密钥（只显示一次）

**注意事项**：

- ⚠️ API 密钥是敏感信息，不要提交到代码仓库
- ⚠️ 不要在公开场合分享你的密钥
- ⚠️ 定期轮换密钥以提高安全性
- 💡 使用环境变量存储密钥

**费用说明**：

- Claude API 按使用量计费
- 新用户通常有免费额度
- 查看 [定价页面](https://www.anthropic.com/pricing) 了解详情
- 在 Console 中可以设置使用限额

## 推荐软件

### 1. devenv（强烈推荐）

**用途**：提供可复现的开发环境，自动配置所有依赖

**优势**：

- ✅ 一键配置完整开发环境
- ✅ 跨平台一致性（macOS、Linux）
- ✅ 自动安装 Go、Node.js、Python、Rust 等工具链
- ✅ 项目隔离，不影响系统环境
- ✅ 包含 ripgrep 等必需工具

**安装方法**：

```bash
# 安装 Nix（devenv 的基础）
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 安装 devenv
nix profile install --accept-flake-config github:cachix/devenv/latest
```

**使用方法**：

```bash
# 进入项目目录
cd /path/to/project

# 启动开发环境
devenv shell

# 环境会自动配置所有依赖
```

**验证安装**：

```bash
devenv shell
# 应该看到欢迎信息和工具版本列表
```

### 2. ripgrep（代码搜索工具）

**用途**：高性能代码搜索，用于 `code_search_tool.go`

**版本要求**：ripgrep 13.0 或更高版本

**检查是否已安装**：

```bash
rg --version
```

**安装方法**：

- **macOS**：
  ```bash
  brew install ripgrep
  ```

- **Linux**：
  ```bash
  # Ubuntu/Debian
  sudo apt install ripgrep
  
  # 或从源码安装
  cargo install ripgrep
  ```

- **Windows**：
  ```bash
  # 使用 Chocolatey
  choco install ripgrep
  
  # 或使用 Scoop
  scoop install ripgrep
  ```

**注意**：如果使用 devenv，ripgrep 会自动安装。

### 3. 代码编辑器

**推荐选项**：

- **Visual Studio Code**（推荐）
  - 安装 Go 扩展
  - 安装 Markdown 扩展
  - 配置 Go 工具链

- **GoLand**
  - JetBrains 的专业 Go IDE
  - 内置完整的 Go 支持

- **Vim/Neovim**
  - 安装 vim-go 插件
  - 配置 LSP 支持

**VS Code 推荐扩展**：

```json
{
  "recommendations": [
    "golang.go",
    "ms-vscode.makefile-tools",
    "yzhang.markdown-all-in-one"
  ]
}
```

## 可选软件

### 1. Node.js 和 TypeScript

**用途**：如果你想扩展项目或运行某些示例

**版本要求**：Node.js 20.x 或更高版本

**安装方法**：

```bash
# macOS
brew install node

# Linux
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 验证
node --version
npm --version
```

**注意**：devenv 会自动安装 Node.js 20。

### 2. Python

**用途**：某些工具或脚本可能需要 Python

**版本要求**：Python 3.11 或更高版本

**安装方法**：

```bash
# macOS
brew install python@3.11

# Linux
sudo apt install python3.11

# 验证
python3 --version
```

**注意**：devenv 会自动安装 Python 3.11。

### 3. Rust

**用途**：如果你想从源码编译某些工具（如 ripgrep）

**安装方法**：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**注意**：devenv 会自动安装 Rust 工具链。

### 4. .NET SDK

**用途**：如果你想用 C# 扩展项目

**版本要求**：.NET 8.0 或更高版本

**注意**：devenv 会自动安装 .NET SDK。

## 系统要求

### 操作系统

**支持的平台**：

- ✅ **macOS**：10.15 (Catalina) 或更高版本
- ✅ **Linux**：主流发行版（Ubuntu 20.04+, Debian 11+, Fedora 35+）
- ✅ **Windows**：Windows 10/11（需要 WSL2 以使用 devenv）

**Windows 用户注意**：

- 推荐使用 WSL2 (Windows Subsystem for Linux)
- 在 WSL2 中按照 Linux 的安装步骤操作
- 或者使用原生 Windows 环境（不支持 devenv）

### 硬件要求

**最低配置**：

- **CPU**：双核处理器
- **内存**：4 GB RAM
- **磁盘**：1 GB 可用空间
- **网络**：稳定的互联网连接（用于 API 调用）

**推荐配置**：

- **CPU**：四核或更高
- **内存**：8 GB RAM 或更多
- **磁盘**：5 GB 可用空间（包含 devenv 和所有工具）
- **网络**：高速互联网连接

## 开发环境配置

### 方案 1：使用 devenv（推荐）

**优势**：

- 自动配置所有依赖
- 环境隔离，不污染系统
- 跨平台一致性
- 包含所有必需和可选工具

**步骤**：

1. 安装 Nix 和 devenv（见上文）
2. 克隆项目仓库
3. 运行 `devenv shell`
4. 完成！所有工具已就绪

**适用场景**：

- 首次接触项目
- 需要快速开始
- 多人协作开发
- 跨平台开发

### 方案 2：手动配置

**优势**：

- 完全控制环境
- 使用系统已有的工具
- 不需要学习 Nix/devenv

**步骤**：

1. 安装 Go 1.24.2+
2. 安装 Git
3. 安装 ripgrep（可选，用于步骤 6）
4. 克隆项目仓库
5. 运行 `go mod tidy`
6. 配置 API 密钥

**适用场景**：

- 已有完整的 Go 开发环境
- 不想使用 Nix/devenv
- 只需要运行部分功能

## 环境变量配置

### ANTHROPIC_API_KEY

**必需**：是

**配置方法**：

```bash
# 临时设置（当前终端会话）
export ANTHROPIC_API_KEY="your-api-key-here"

# 永久设置（添加到 shell 配置文件）
# Bash
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc

# Zsh
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc

# Fish
set -Ux ANTHROPIC_API_KEY "your-api-key-here"
```

**验证配置**：

```bash
echo $ANTHROPIC_API_KEY
# 应该输出你的 API 密钥
```

### GOPATH 和 GOROOT

**通常不需要手动配置**，Go 会自动设置。

**查看当前配置**：

```bash
go env GOPATH
go env GOROOT
```

## 网络要求

### API 访问

**需要访问的域名**：

- `api.anthropic.com` - Claude API 端点
- `console.anthropic.com` - 管理控制台

**网络要求**：

- 稳定的 HTTPS 连接
- 支持 TLS 1.2 或更高版本
- 无需特殊代理配置（除非你的网络有限制）

**代理配置**（如果需要）：

```bash
# HTTP 代理
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"

# SOCKS5 代理
export ALL_PROXY="socks5://proxy.example.com:1080"
```

### 包管理器访问

**Go 模块**：

- `proxy.golang.org` - Go 模块代理
- `sum.golang.org` - 校验和数据库

**Nix/devenv**（如果使用）：

- `cache.nixos.org` - Nix 二进制缓存
- `github.com` - 源码仓库

## 检查清单

在继续之前，请确认以下项目：

- [ ] Go 1.24.2+ 已安装并可用
- [ ] Git 已安装
- [ ] 已获取 Anthropic API 密钥
- [ ] API 密钥已配置为环境变量
- [ ] （推荐）devenv 已安装并可用
- [ ] （可选）ripgrep 已安装（用于步骤 6）
- [ ] 网络连接正常，可以访问 Anthropic API
- [ ] 代码编辑器已配置好

**快速验证脚本**：

```bash
#!/bin/bash

echo "检查 Go..."
go version || echo "❌ Go 未安装"

echo "检查 Git..."
git --version || echo "❌ Git 未安装"

echo "检查 API 密钥..."
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ ANTHROPIC_API_KEY 未设置"
else
    echo "✅ ANTHROPIC_API_KEY 已设置"
fi

echo "检查 ripgrep（可选）..."
rg --version || echo "⚠️  ripgrep 未安装（步骤 6 需要）"

echo "检查 devenv（可选）..."
devenv version || echo "⚠️  devenv 未安装（推荐安装）"

echo ""
echo "检查完成！"
```

## 常见问题

### Q: 我必须使用 devenv 吗？

**A**: 不是必须的。devenv 是推荐的方式，因为它能自动配置所有依赖。但如果你已经有完整的 Go 开发环境，可以手动配置。

### Q: Go 版本必须是 1.24.2 吗？

**A**: 不是。1.24.2 是推荐版本，但任何 1.24.x 或更高版本都应该可以工作。

### Q: 我没有 API 密钥可以运行项目吗？

**A**: 不可以。项目需要调用 Claude API，必须有有效的 API 密钥。你可以在 Anthropic 官网注册获取。

### Q: ripgrep 是必需的吗？

**A**: 只有在运行步骤 6（`code_search_tool.go`）时才需要。前 5 个步骤不需要 ripgrep。

### Q: Windows 用户应该如何配置？

**A**: 推荐使用 WSL2，在 Linux 环境中按照 Linux 的步骤操作。或者使用原生 Windows 环境，但不支持 devenv。

### Q: 如何检查我的环境是否配置正确？

**A**: 运行上面的"快速验证脚本"，或者直接尝试运行 `go run chat.go`，如果能正常启动就说明环境配置正确。

## 下一步

环境准备好后，请继续：

- **[安装配置](installation.md)** - 克隆项目并配置（即将推出）
- **[快速开始](quick-start.md)** - 运行第一个示例（即将推出）

如果遇到问题，请查看：

- **[故障排查](../troubleshooting/common-issues.md)** - 常见问题解决方案（即将推出）
- **[调试技巧](../troubleshooting/debugging.md)** - 调试方法（即将推出）

---

**提示**：如果你是第一次接触 Go 或 AI 开发，建议使用 devenv 方案，可以避免很多配置问题。
