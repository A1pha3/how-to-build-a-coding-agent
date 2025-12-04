#!/bin/bash

# 链接验证脚本
# 验证文档中所有内部链接的有效性

set -e

DOCS_DIR="docs"
REPORT_FILE="docs/links-report.md"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "链接有效性验证"
echo "=========================================="
echo ""

if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}错误: 文档目录不存在: $DOCS_DIR${NC}"
    exit 1
fi

# 初始化计数器
total_links=0
valid_links=0
broken_links=()

# 临时文件
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

echo "扫描文档中的内部链接..."
echo ""

# 查找所有 markdown 文件并提取链接
find "$DOCS_DIR" -name "*.md" -type f | while read -r doc_file; do
    echo "检查: $doc_file"
    
    # 提取 markdown 链接 [text](link)
    grep -oE '\[([^\]]+)\]\(([^)]+)\)' "$doc_file" | while read -r link_match; do
        # 提取链接目标
        link_target=$(echo "$link_match" | sed -E 's/\[([^\]]+)\]\(([^)]+)\)/\2/')
        
        # 只处理相对路径链接（内部链接）
        if [[ ! "$link_target" =~ ^https?:// ]] && [[ ! "$link_target" =~ ^mailto: ]]; then
            echo "$doc_file|$link_target" >> "$TEMP_FILE"
        fi
    done
done

echo ""
echo "验证链接目标..."
echo ""

# 验证每个链接
if [ -f "$TEMP_FILE" ]; then
    while IFS='|' read -r source_file link_target; do
        total_links=$((total_links + 1))
        
        # 获取源文件所在目录
        source_dir=$(dirname "$source_file")
        
        # 处理锚点链接
        if [[ "$link_target" =~ ^# ]]; then
            # 同文件内的锚点链接，假设有效
            valid_links=$((valid_links + 1))
            echo -e "${GREEN}✓${NC} $source_file -> $link_target (锚点)"
            continue
        fi
        
        # 分离文件路径和锚点
        if [[ "$link_target" =~ ^([^#]+)(#.+)?$ ]]; then
            file_path="${BASH_REMATCH[1]}"
            anchor="${BASH_REMATCH[2]}"
        else
            file_path="$link_target"
            anchor=""
        fi
        
        # 解析相对路径
        if [[ "$file_path" =~ ^\.\. ]]; then
            # 相对于源文件的路径
            target_path="$source_dir/$file_path"
        elif [[ "$file_path" =~ ^\. ]]; then
            # 相对于源文件的路径
            target_path="$source_dir/$file_path"
        else
            # 相对于文档根目录
            target_path="$DOCS_DIR/$file_path"
        fi
        
        # 规范化路径
        target_path=$(echo "$target_path" | sed 's#/\./#/#g' | sed 's#/[^/]*/\.\./#/#g')
        
        # 检查目标文件是否存在
        if [ -f "$target_path" ] || [ -d "$target_path" ]; then
            valid_links=$((valid_links + 1))
            echo -e "${GREEN}✓${NC} $source_file -> $link_target"
        else
            broken_links+=("$source_file -> $link_target (目标: $target_path)")
            echo -e "${RED}✗${NC} $source_file -> $link_target (目标不存在: $target_path)"
        fi
    done < "$TEMP_FILE"
fi

echo ""
echo "=========================================="
echo "验证结果"
echo "=========================================="
echo "总链接数: $total_links"
echo "有效链接: $valid_links"
echo "断链数: ${#broken_links[@]}"

if [ $total_links -gt 0 ]; then
    validity=$((valid_links * 100 / total_links))
    echo -e "有效率: ${GREEN}${validity}%${NC}"
fi

echo ""

# 生成报告
cat > "$REPORT_FILE" << EOF
# 链接验证报告

生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 统计摘要

- **总链接数**: $total_links
- **有效链接**: $valid_links
- **断链数**: ${#broken_links[@]}
EOF

if [ $total_links -gt 0 ]; then
    validity=$((valid_links * 100 / total_links))
    echo "- **有效率**: ${validity}%" >> "$REPORT_FILE"
fi

if [ ${#broken_links[@]} -gt 0 ]; then
    cat >> "$REPORT_FILE" << EOF

## 断链列表

EOF
    for broken in "${broken_links[@]}"; do
        echo "- $broken" >> "$REPORT_FILE"
    done
fi

cat >> "$REPORT_FILE" << EOF

## 建议

1. 修复所有断链，确保链接目标存在
2. 使用相对路径引用文档内部资源
3. 定期运行此脚本检查链接有效性

EOF

echo "报告已生成: $REPORT_FILE"
echo ""

# 返回状态
if [ ${#broken_links[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ 所有链接都有效！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ 发现 ${#broken_links[@]} 个断链${NC}"
    exit 1
fi
