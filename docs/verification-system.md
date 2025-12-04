# 文档验证系统

## 概述

文档验证系统是一套自动化脚本，用于确保中文文档系统的质量、完整性和一致性。该系统实现了设计文档中定义的五个核心正确性属性。

## 系统架构

```
scripts/
├── verify-all.sh                      # 主验证脚本
├── verify-documentation-coverage.sh   # 属性 1: 文档完整性
├── verify-code-sync.sh                # 属性 2: 代码同步一致性
├── verify-links.sh                    # 属性 3: 链接有效性
├── verify-naming.sh                   # 属性 4: 文档命名规范性
├── verify-template.sh                 # 属性 5: 模板一致性
└── README.md                          # 使用文档
```

## 验证属性

### 属性 1: 文档完整性
**脚本:** `verify-documentation-coverage.sh`

验证所有需求文档中的验收标准是否都有对应的文档内容。

**实现方式:**
- 定义需求 ID 到文档文件的映射
- 检查每个需求对应的文档是否存在
- 计算覆盖率并生成报告

**输出:** `docs/coverage-report.md`

### 属性 2: 代码同步一致性
**脚本:** `verify-code-sync.sh`

验证文档中的代码示例与项目源代码的一致性。

**实现方式:**
- 扫描所有文档中的 Go 代码块
- 检查源文件是否在文档中被引用
- 验证完整代码示例的语法正确性

**输出:** `docs/code-sync-report.md`

### 属性 3: 链接有效性
**脚本:** `verify-links.sh`

验证文档中所有内部链接的目标是否存在。

**实现方式:**
- 提取所有 Markdown 格式的链接
- 解析相对路径和锚点
- 验证目标文件或目录存在性

**输出:** `docs/links-report.md`

### 属性 4: 文档命名规范性
**脚本:** `verify-naming.sh`

验证文档文件名是否符合命名规范。

**实现方式:**
- 使用正则表达式检查文件名格式
- 识别特殊文件（如 README.md）
- 为不符合规范的文件提供重命名建议

**命名规范:**
- 小写字母
- 连字符分隔
- 只包含字母、数字和连字符
- .md 扩展名

**输出:** `docs/naming-report.md`

### 属性 5: 模板一致性
**脚本:** `verify-template.sh`

验证同类型文档是否遵循相同的模板结构。

**实现方式:**
- 定义各类文档的必需章节
- 检查文档是否包含必需章节
- 按文档类型分组验证

**文档类型:**
- 工作坊教程（必需章节：学习目标、背景知识、实现步骤、运行和测试、代码解析）
- API 参考（必需章节：概述）
- 开发指南（必需：主标题）
- 入门指南（建议：二级标题）

**输出:** `docs/template-report.md`

## 使用方法

### 运行所有验证

```bash
./scripts/verify-all.sh
```

这会依次运行所有验证脚本并生成综合报告。

### 运行单个验证

```bash
# 文档完整性
./scripts/verify-documentation-coverage.sh

# 代码同步
./scripts/verify-code-sync.sh

# 链接有效性
./scripts/verify-links.sh

# 命名规范
./scripts/verify-naming.sh

# 模板一致性
./scripts/verify-template.sh
```

## 报告文件

所有验证脚本都会在 `docs/` 目录生成 Markdown 格式的报告：

| 报告文件 | 内容 |
|---------|------|
| `coverage-report.md` | 需求覆盖率统计和未覆盖需求列表 |
| `code-sync-report.md` | 代码引用检查和语法验证结果 |
| `links-report.md` | 链接有效性统计和断链列表 |
| `naming-report.md` | 命名规范检查和重命名建议 |
| `template-report.md` | 模板一致性检查和缺失章节 |

## 集成到工作流

### 开发阶段

在修改文档后运行验证：

```bash
# 编辑文档
vim docs/guides/creating-tools.md

# 验证更改
./scripts/verify-all.sh
```

### 代码审查

在提交 PR 前运行验证：

```bash
# 提交前检查
./scripts/verify-all.sh

# 如果有问题，查看报告
cat docs/coverage-report.md
```

### 持续集成

在 CI/CD 流程中集成：

```yaml
# GitHub Actions 示例
name: Documentation Verification
on: [push, pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run verification
        run: ./scripts/verify-all.sh
```

## 退出状态

所有脚本遵循标准退出状态：

- `0` - 验证通过
- `1` - 验证失败（发现问题）

这使得脚本可以用于自动化流程的门控检查。

## 扩展性

系统设计为可扩展的：

1. **添加新验证** - 创建新脚本并添加到 `verify-all.sh`
2. **自定义规则** - 修改现有脚本的验证逻辑
3. **集成工具** - 调用外部工具进行更深入的检查

## 维护

### 更新需求映射

当添加新需求时，更新 `verify-documentation-coverage.sh` 中的映射：

```bash
check_requirement "新需求ID" "对应文档路径"
```

### 更新模板规则

当修改文档模板时，更新 `verify-template.sh` 中的章节定义。

### 定期审查

建议定期运行验证并审查报告，确保文档质量持续改进。

## 技术细节

### 实现语言
- Bash shell 脚本
- 使用标准 Unix 工具（grep, awk, find）

### 依赖
- bash (>= 4.0)
- grep
- awk
- find
- go (用于代码语法检查)

### 兼容性
- macOS
- Linux
- Windows (WSL)

## 已知限制

1. **代码同步验证** - 只检查语法，不验证语义正确性
2. **链接验证** - 不检查外部链接的可访问性
3. **模板验证** - 只检查章节存在性，不验证内容质量

## 未来改进

1. 添加外部链接检查
2. 集成代码覆盖率工具
3. 添加文档可读性评分
4. 支持多语言文档验证
5. 生成 HTML 格式的报告

## 相关文档

- [脚本使用说明](../scripts/README.md)
- [设计文档](../.kiro/specs/chinese-documentation/design.md)
- [需求文档](../.kiro/specs/chinese-documentation/requirements.md)
