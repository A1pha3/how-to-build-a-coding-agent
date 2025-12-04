# 文档验证脚本

本目录包含用于验证中文文档系统质量和一致性的脚本。

## 脚本列表

### 1. verify-all.sh
**主验证脚本** - 运行所有验证检查并生成综合报告。

```bash
./scripts/verify-all.sh
```

这是推荐的验证方式，会依次运行所有验证脚本。

### 2. verify-documentation-coverage.sh
**文档完整性验证** - 检查所有需求是否都有对应的文档覆盖。

```bash
./scripts/verify-documentation-coverage.sh
```

**验证内容:**
- 检查需求文档中的每个验收标准
- 确认对应的文档文件存在
- 生成覆盖率报告

**输出报告:** `docs/coverage-report.md`

### 3. verify-code-sync.sh
**代码同步验证** - 验证文档中的代码示例与源代码的一致性。

```bash
./scripts/verify-code-sync.sh
```

**验证内容:**
- 扫描文档中的 Go 代码块
- 检查源文件是否在文档中被引用
- 验证完整代码示例的语法正确性

**输出报告:** `docs/code-sync-report.md`

### 4. verify-links.sh
**链接有效性验证** - 检查文档中所有内部链接的有效性。

```bash
./scripts/verify-links.sh
```

**验证内容:**
- 提取所有 Markdown 链接
- 验证内部链接的目标文件存在
- 生成断链报告

**输出报告:** `docs/links-report.md`

### 5. verify-naming.sh
**命名规范验证** - 检查文档文件名是否符合命名规范。

```bash
./scripts/verify-naming.sh
```

**验证内容:**
- 检查文件名格式（小写字母、连字符）
- 识别不符合规范的文件
- 提供重命名建议

**命名规范:**
- 使用小写字母
- 单词之间使用连字符（-）分隔
- 只包含字母、数字和连字符
- 以 .md 结尾

**输出报告:** `docs/naming-report.md`

### 6. verify-template.sh
**模板一致性验证** - 检查同类型文档是否遵循相同的模板结构。

```bash
./scripts/verify-template.sh
```

**验证内容:**
- 检查工作坊教程的必需章节
- 验证 API 参考文档的结构
- 确认开发指南的完整性

**输出报告:** `docs/template-report.md`

## 使用场景

### 日常开发
在修改文档后运行验证脚本，确保质量：

```bash
# 快速验证所有内容
./scripts/verify-all.sh

# 或单独运行特定验证
./scripts/verify-naming.sh
```

### 持续集成
在 CI/CD 流程中集成验证脚本：

```yaml
# 示例 GitHub Actions 配置
- name: Verify Documentation
  run: ./scripts/verify-all.sh
```

### 文档审查
在提交 PR 前运行验证，确保文档质量：

```bash
# 检查文档完整性
./scripts/verify-documentation-coverage.sh

# 检查链接有效性
./scripts/verify-links.sh
```

## 报告文件

所有验证脚本都会在 `docs/` 目录下生成报告文件：

- `coverage-report.md` - 需求覆盖率报告
- `code-sync-report.md` - 代码同步报告
- `links-report.md` - 链接验证报告
- `naming-report.md` - 命名规范报告
- `template-report.md` - 模板一致性报告

## 退出状态

所有脚本遵循标准的退出状态约定：

- `0` - 验证通过，没有问题
- `1` - 验证失败，发现问题

这使得脚本可以轻松集成到自动化流程中。

## 故障排查

### 权限问题
如果遇到权限错误，确保脚本有执行权限：

```bash
chmod +x scripts/*.sh
```

### 路径问题
所有脚本应该从项目根目录运行：

```bash
cd /path/to/project
./scripts/verify-all.sh
```

### 依赖问题
脚本依赖以下工具（通常已预装）：
- bash
- grep
- awk
- find
- go (用于代码语法检查)

## 扩展

要添加新的验证脚本：

1. 在 `scripts/` 目录创建新脚本
2. 遵循现有脚本的结构和命名约定
3. 在 `verify-all.sh` 中添加调用
4. 更新本 README 文档

## 维护

这些脚本是文档系统的一部分，应该与文档一起维护：

- 当添加新需求时，更新 `verify-documentation-coverage.sh`
- 当修改文档结构时，更新 `verify-template.sh`
- 定期运行验证，确保文档质量
