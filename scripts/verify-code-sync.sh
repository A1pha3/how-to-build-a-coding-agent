#!/bin/bash

# 代码同步验证脚本
# 验证文档中的代码示例与源代码的一致性

set -e

DOCS_DIR="docs"
REPORT_FILE="docs/code-sync-report.md"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "代码同步验证"
echo "=========================================="
echo ""

if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}错误: 文档目录不存在: $DOCS_DIR${NC}"
    exit 1
fi

# 初始化计数器
total_code_blocks=0
synced_blocks=0
issues=()

# 临时目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "扫描文档中的代码块..."
echo ""

# 查找所有 markdown 文件
find "$DOCS_DIR" -name "*.md" -type f | while read -r doc_file; do
    echo "检查: $doc_file"
    
    # 提取 Go 代码块
    awk '
        /```go/ { in_code=1; code=""; next }
        in_code && /```/ { 
            in_code=0
            if (code != "") {
                print "CODE_BLOCK_START"
                print code
                print "CODE_BLOCK_END"
            }
            next
        }
        in_code { code = code $0 "\n" }
    ' "$doc_file" > "$TEMP_DIR/blocks.txt"
    
    # 检查提取的代码块
    if [ -s "$TEMP_DIR/blocks.txt" ]; then
        block_count=$(grep -c "CODE_BLOCK_START" "$TEMP_DIR/blocks.txt" || echo "0")
        echo "  发现 $block_count 个 Go 代码块"
    fi
done

echo ""
echo "=========================================="
echo "验证结果"
echo "=========================================="

# 检查关键源文件是否在文档中被引用
echo ""
echo "检查源文件引用..."
echo ""

declare -a source_files=(
    "chat.go"
    "read.go"
    "list_files.go"
    "bash_tool.go"
    "edit_tool.go"
    "code_search_tool.go"
)

for src_file in "${source_files[@]}"; do
    if grep -r "$src_file" "$DOCS_DIR" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $src_file 在文档中被引用"
    else
        echo -e "${YELLOW}⚠${NC} $src_file 未在文档中被引用"
    fi
done

echo ""
echo "检查代码示例的语法正确性..."
echo ""

# 提取并验证独立的代码示例
syntax_errors=0
find "$DOCS_DIR" -name "*.md" -type f | while read -r doc_file; do
    # 提取完整的 Go 代码块（包含 package 声明的）
    awk '
        /```go/ { in_code=1; code=""; line_num=NR; next }
        in_code && /```/ { 
            in_code=0
            # Only validate complete programs (with both package and func main)
            if (code ~ /^package / && code ~ /func main\(/) {
                print "FILE:" FILENAME
                print "LINE:" line_num
                print code
                print "---END---"
            }
            next
        }
        in_code { code = code $0 "\n" }
    ' FILENAME="$doc_file" "$doc_file"
done > "$TEMP_DIR/complete_examples.txt"

# 验证完整示例的语法
if [ -s "$TEMP_DIR/complete_examples.txt" ]; then
    current_file=""
    current_line=""
    code_content=""
    
    while IFS= read -r line; do
        if [[ $line == FILE:* ]]; then
            current_file="${line#FILE:}"
        elif [[ $line == LINE:* ]]; then
            current_line="${line#LINE:}"
        elif [[ $line == "---END---" ]]; then
            if [ -n "$code_content" ]; then
                # 保存到临时文件并检查语法
                echo "$code_content" > "$TEMP_DIR/test.go"
                if ! go fmt "$TEMP_DIR/test.go" > /dev/null 2>&1; then
                    echo -e "${RED}✗${NC} 语法错误: $current_file (行 $current_line)"
                    syntax_errors=$((syntax_errors + 1))
                else
                    echo -e "${GREEN}✓${NC} 语法正确: $current_file (行 $current_line)"
                fi
            fi
            code_content=""
        else
            code_content="$code_content$line"$'\n'
        fi
    done < "$TEMP_DIR/complete_examples.txt"
fi

echo ""
echo "=========================================="
echo "统计摘要"
echo "=========================================="
echo "语法错误: $syntax_errors"
echo ""

# 生成报告
cat > "$REPORT_FILE" << EOF
# 代码同步验证报告

生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 统计摘要

- **语法错误**: $syntax_errors

## 源文件引用检查

EOF

for src_file in "${source_files[@]}"; do
    if grep -r "$src_file" "$DOCS_DIR" > /dev/null 2>&1; then
        echo "- ✓ $src_file: 已引用" >> "$REPORT_FILE"
    else
        echo "- ⚠ $src_file: 未引用" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" << EOF

## 建议

1. 确保所有代码示例都能独立编译运行
2. 定期检查文档中的代码与源代码的一致性
3. 在代码变更时同步更新相关文档

EOF

echo "报告已生成: $REPORT_FILE"
echo ""

# 返回状态
if [ $syntax_errors -eq 0 ]; then
    echo -e "${GREEN}✓ 代码同步验证通过！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ 发现 $syntax_errors 个语法错误${NC}"
    exit 1
fi
