#!/bin/bash

# 命名规范验证脚本
# 验证文档文件名是否符合命名规范

set -e

DOCS_DIR="docs"
REPORT_FILE="docs/naming-report.md"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "文档命名规范验证"
echo "=========================================="
echo ""

if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}错误: 文档目录不存在: $DOCS_DIR${NC}"
    exit 1
fi

# 初始化计数器
total_files=0
compliant_files=0
non_compliant_files=()

echo "检查文档文件命名..."
echo ""

# 命名规范：小写字母、数字、连字符，以 .md 结尾
# 允许的模式：lowercase-with-hyphens.md
NAMING_PATTERN='^[a-z0-9]+(-[a-z0-9]+)*\.md$'

# 特殊文件（允许大写）
SPECIAL_FILES=(
    "README.md"
    "CHANGELOG.md"
    "LICENSE.md"
    "CONTRIBUTING.md"
)

# 查找所有 markdown 文件
find "$DOCS_DIR" -name "*.md" -type f | while read -r file_path; do
    total_files=$((total_files + 1))
    
    # 获取文件名（不含路径）
    filename=$(basename "$file_path")
    
    # 检查是否是特殊文件
    is_special=false
    for special in "${SPECIAL_FILES[@]}"; do
        if [ "$filename" = "$special" ]; then
            is_special=true
            break
        fi
    done
    
    # 验证命名规范
    if [ "$is_special" = true ]; then
        compliant_files=$((compliant_files + 1))
        echo -e "${GREEN}✓${NC} $file_path (特殊文件)"
    elif [[ "$filename" =~ $NAMING_PATTERN ]]; then
        compliant_files=$((compliant_files + 1))
        echo -e "${GREEN}✓${NC} $file_path"
    else
        non_compliant_files+=("$file_path")
        echo -e "${RED}✗${NC} $file_path (不符合命名规范)"
        
        # 提供建议的文件名
        suggested_name=$(echo "$filename" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9.-]/-/g' | sed 's/--*/-/g')
        echo -e "    ${YELLOW}建议: $suggested_name${NC}"
    fi
done > /tmp/naming_check.txt

# 读取结果
total_files=$(grep -c "✓\|✗" /tmp/naming_check.txt 2>/dev/null || echo "0")
total_files=$(echo "$total_files" | tr -d '\n')
compliant_files=$(grep -c "✓" /tmp/naming_check.txt 2>/dev/null || echo "0")
compliant_files=$(echo "$compliant_files" | tr -d '\n')
non_compliant_count=$(grep -c "✗" /tmp/naming_check.txt 2>/dev/null || echo "0")
non_compliant_count=$(echo "$non_compliant_count" | tr -d '\n')

cat /tmp/naming_check.txt
rm -f /tmp/naming_check.txt

echo ""
echo "=========================================="
echo "验证结果"
echo "=========================================="
echo "总文件数: $total_files"
echo "符合规范: $compliant_files"
echo "不符合规范: $non_compliant_count"

if [ $total_files -gt 0 ]; then
    compliance=$((compliant_files * 100 / total_files))
    echo -e "合规率: ${GREEN}${compliance}%${NC}"
fi

echo ""

# 生成报告
cat > "$REPORT_FILE" << EOF
# 文档命名规范验证报告

生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 命名规范

文档文件名应遵循以下规范：

1. 使用小写字母
2. 单词之间使用连字符（-）分隔
3. 只包含字母、数字和连字符
4. 以 .md 结尾

**示例**：
- ✓ getting-started.md
- ✓ api-reference.md
- ✓ step-1-chat.md
- ✗ Getting_Started.md
- ✗ API Reference.md

**特殊文件**（允许大写）：
- README.md
- CHANGELOG.md
- LICENSE.md
- CONTRIBUTING.md

## 统计摘要

- **总文件数**: $total_files
- **符合规范**: $compliant_files
- **不符合规范**: $non_compliant_count
EOF

if [ $total_files -gt 0 ]; then
    compliance=$((compliant_files * 100 / total_files))
    echo "- **合规率**: ${compliance}%" >> "$REPORT_FILE"
fi

# 列出不符合规范的文件
if [ "$non_compliant_count" -gt 0 ]; then
    cat >> "$REPORT_FILE" << EOF

## 不符合规范的文件

EOF
    find "$DOCS_DIR" -name "*.md" -type f | while read -r file_path; do
        filename=$(basename "$file_path")
        
        # 检查是否是特殊文件
        is_special=false
        for special in "${SPECIAL_FILES[@]}"; do
            if [ "$filename" = "$special" ]; then
                is_special=true
                break
            fi
        done
        
        if [ "$is_special" = false ] && [[ ! "$filename" =~ $NAMING_PATTERN ]]; then
            suggested_name=$(echo "$filename" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9.-]/-/g' | sed 's/--*/-/g')
            echo "- \`$file_path\`" >> "$REPORT_FILE"
            echo "  - 建议: \`$suggested_name\`" >> "$REPORT_FILE"
        fi
    done
fi

cat >> "$REPORT_FILE" << EOF

## 建议

1. 重命名不符合规范的文件
2. 更新文档中指向这些文件的链接
3. 在创建新文档时遵循命名规范

EOF

echo "报告已生成: $REPORT_FILE"
echo ""

# 返回状态
if [ "$non_compliant_count" -eq 0 ]; then
    echo -e "${GREEN}✓ 所有文件名都符合规范！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ 发现 $non_compliant_count 个不符合规范的文件名${NC}"
    exit 1
fi
