#!/bin/bash

# 模板一致性验证脚本
# 验证同类型文档是否遵循相同的模板结构

set -e

DOCS_DIR="docs"
REPORT_FILE="docs/template-report.md"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "文档模板一致性验证"
echo "=========================================="
echo ""

if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}错误: 文档目录不存在: $DOCS_DIR${NC}"
    exit 1
fi

# 定义各类文档的必需章节
declare -A workshop_sections=(
    ["学习目标"]=1
    ["背景知识"]=1
    ["实现步骤"]=1
    ["运行和测试"]=1
    ["代码解析"]=1
)

declare -A api_sections=(
    ["概述"]=1
    ["函数"]=0
    ["类型定义"]=0
)

declare -A guide_sections=(
    ["简介"]=1
)

# 初始化计数器
total_docs=0
compliant_docs=0
issues=()

echo "检查工作坊教程文档..."
echo ""

# 检查工作坊文档
for step_file in "$DOCS_DIR/workshop"/step-*.md; do
    if [ -f "$step_file" ]; then
        total_docs=$((total_docs + 1))
        filename=$(basename "$step_file")
        echo "检查: $filename"
        
        missing_sections=()
        for section in "${!workshop_sections[@]}"; do
            if ! grep -q "## $section" "$step_file"; then
                missing_sections+=("$section")
            fi
        done
        
        if [ ${#missing_sections[@]} -eq 0 ]; then
            compliant_docs=$((compliant_docs + 1))
            echo -e "  ${GREEN}✓${NC} 结构完整"
        else
            echo -e "  ${RED}✗${NC} 缺少章节: ${missing_sections[*]}"
            issues+=("$filename: 缺少章节 - ${missing_sections[*]}")
        fi
    fi
done

echo ""
echo "检查 API 参考文档..."
echo ""

# 检查 API 文档
for api_file in "$DOCS_DIR/api-reference"/*.md; do
    if [ -f "$api_file" ]; then
        total_docs=$((total_docs + 1))
        filename=$(basename "$api_file")
        echo "检查: $filename"
        
        missing_sections=()
        for section in "${!api_sections[@]}"; do
            required=${api_sections[$section]}
            if [ $required -eq 1 ] && ! grep -q "## $section" "$api_file"; then
                missing_sections+=("$section")
            fi
        done
        
        if [ ${#missing_sections[@]} -eq 0 ]; then
            compliant_docs=$((compliant_docs + 1))
            echo -e "  ${GREEN}✓${NC} 结构完整"
        else
            echo -e "  ${RED}✗${NC} 缺少章节: ${missing_sections[*]}"
            issues+=("$filename: 缺少章节 - ${missing_sections[*]}")
        fi
    fi
done

echo ""
echo "检查开发指南文档..."
echo ""

# 检查指南文档
for guide_file in "$DOCS_DIR/guides"/*.md; do
    if [ -f "$guide_file" ]; then
        total_docs=$((total_docs + 1))
        filename=$(basename "$guide_file")
        echo "检查: $filename"
        
        # 指南文档结构较灵活，只检查是否有标题
        if grep -q "^# " "$guide_file"; then
            compliant_docs=$((compliant_docs + 1))
            echo -e "  ${GREEN}✓${NC} 结构完整"
        else
            echo -e "  ${RED}✗${NC} 缺少主标题"
            issues+=("$filename: 缺少主标题")
        fi
    fi
done

echo ""
echo "检查入门指南文档..."
echo ""

# 检查入门文档
for getting_started_file in "$DOCS_DIR/getting-started"/*.md; do
    if [ -f "$getting_started_file" ]; then
        total_docs=$((total_docs + 1))
        filename=$(basename "$getting_started_file")
        echo "检查: $filename"
        
        # 入门文档应该有清晰的章节结构
        if grep -q "^## " "$getting_started_file"; then
            compliant_docs=$((compliant_docs + 1))
            echo -e "  ${GREEN}✓${NC} 结构完整"
        else
            echo -e "  ${YELLOW}⚠${NC} 缺少二级标题"
            issues+=("$filename: 建议添加二级标题")
        fi
    fi
done

echo ""
echo "=========================================="
echo "验证结果"
echo "=========================================="
echo "总文档数: $total_docs"
echo "结构完整: $compliant_docs"
echo "存在问题: ${#issues[@]}"

if [ $total_docs -gt 0 ]; then
    compliance=$((compliant_docs * 100 / total_docs))
    echo -e "合规率: ${GREEN}${compliance}%${NC}"
fi

echo ""

# 生成报告
cat > "$REPORT_FILE" << EOF
# 文档模板一致性验证报告

生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 文档模板规范

### 工作坊教程模板

工作坊教程文档应包含以下章节：

1. **学习目标** - 说明本步骤的学习目标
2. **背景知识** - 介绍必要的前置知识
3. **实现步骤** - 详细的实现过程
4. **运行和测试** - 如何运行和测试代码
5. **代码解析** - 关键代码的详细解释

### API 参考模板

API 参考文档应包含以下章节：

1. **概述** - API 的用途和功能（必需）
2. **函数** - 函数列表和详细说明（可选）
3. **类型定义** - 数据类型定义（可选）

### 开发指南模板

开发指南文档应包含：

1. **主标题** - 清晰的文档标题
2. **简介** - 说明指南的目的
3. **内容章节** - 根据主题组织的内容

## 统计摘要

- **总文档数**: $total_docs
- **结构完整**: $compliant_docs
- **存在问题**: ${#issues[@]}
EOF

if [ $total_docs -gt 0 ]; then
    compliance=$((compliant_docs * 100 / total_docs))
    echo "- **合规率**: ${compliance}%" >> "$REPORT_FILE"
fi

# 列出存在问题的文档
if [ ${#issues[@]} -gt 0 ]; then
    cat >> "$REPORT_FILE" << EOF

## 存在问题的文档

EOF
    for issue in "${issues[@]}"; do
        echo "- $issue" >> "$REPORT_FILE"
    done
fi

cat >> "$REPORT_FILE" << EOF

## 建议

1. 确保同类型文档遵循相同的模板结构
2. 补充缺失的必需章节
3. 保持文档结构的一致性，便于读者理解

EOF

echo "报告已生成: $REPORT_FILE"
echo ""

# 返回状态
if [ ${#issues[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ 所有文档模板都一致！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ 发现 ${#issues[@]} 个模板问题${NC}"
    exit 1
fi
