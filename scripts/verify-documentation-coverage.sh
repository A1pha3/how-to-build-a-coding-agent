#!/bin/bash

# 文档完整性验证脚本
# 验证所有需求的验收标准是否都有对应的文档内容

set -e

REQUIREMENTS_FILE=".kiro/specs/chinese-documentation/requirements.md"
DOCS_DIR="docs"
REPORT_FILE="docs/coverage-report.md"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "文档完整性验证"
echo "=========================================="
echo ""

# 检查必需文件是否存在
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}错误: 需求文档不存在: $REQUIREMENTS_FILE${NC}"
    exit 1
fi

if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}错误: 文档目录不存在: $DOCS_DIR${NC}"
    exit 1
fi

# 初始化计数器
total_requirements=0
covered_requirements=0

# 临时文件
TEMP_RESULTS=$(mktemp)
trap "rm -f $TEMP_RESULTS" EXIT

echo "检查需求覆盖率..."
echo ""

# 定义需求检查函数
check_requirement() {
    local req_id="$1"
    shift
    local docs="$@"
    
    total_requirements=$((total_requirements + 1))
    
    # 检查文档是否存在
    local all_exist=true
    for doc in $docs; do
        if [ ! -f "$doc" ]; then
            all_exist=false
            break
        fi
    done
    
    if [ "$all_exist" = true ]; then
        covered_requirements=$((covered_requirements + 1))
        echo -e "${GREEN}✓${NC} 需求 $req_id: 已覆盖"
        echo "COVERED|$req_id|$docs" >> "$TEMP_RESULTS"
    else
        echo -e "${RED}✗${NC} 需求 $req_id: 缺失文档 ($docs)"
        echo "MISSING|$req_id|$docs" >> "$TEMP_RESULTS"
    fi
}

# 检查所有需求
check_requirement "1.1" "docs/README.md"
check_requirement "1.2" "docs/getting-started/overview.md"
check_requirement "1.3" "docs/getting-started/overview.md"
check_requirement "1.4" "docs/getting-started/quick-start.md"
check_requirement "2.1" "docs/getting-started/prerequisites.md"
check_requirement "2.2" "docs/getting-started/installation.md"
check_requirement "2.3" "docs/getting-started/installation.md"
check_requirement "2.4" "docs/troubleshooting/common-issues.md"
check_requirement "2.5" "docs/getting-started/installation.md"
check_requirement "3.1" "docs/architecture/overview.md" "docs/architecture/agent-design.md" "docs/architecture/event-loop.md"
check_requirement "3.2" "docs/architecture/tool-system.md"
check_requirement "3.3" "docs/architecture/overview.md"
check_requirement "3.4" "docs/architecture/overview.md"
check_requirement "3.5" "docs/architecture/agent-design.md" "docs/architecture/tool-system.md" "docs/architecture/event-loop.md"
check_requirement "4.1" "docs/workshop/step-1-chat.md" "docs/workshop/step-2-read.md" "docs/workshop/step-3-list.md" "docs/workshop/step-4-bash.md" "docs/workshop/step-5-edit.md" "docs/workshop/step-6-search.md"
check_requirement "4.2" "docs/workshop/step-1-chat.md" "docs/workshop/step-2-read.md" "docs/workshop/step-3-list.md" "docs/workshop/step-4-bash.md" "docs/workshop/step-5-edit.md" "docs/workshop/step-6-search.md"
check_requirement "4.3" "docs/workshop/step-1-chat.md" "docs/workshop/step-2-read.md" "docs/workshop/step-3-list.md" "docs/workshop/step-4-bash.md" "docs/workshop/step-5-edit.md" "docs/workshop/step-6-search.md"
check_requirement "4.4" "docs/workshop/step-1-chat.md" "docs/workshop/step-2-read.md" "docs/workshop/step-3-list.md" "docs/workshop/step-4-bash.md" "docs/workshop/step-5-edit.md" "docs/workshop/step-6-search.md"
check_requirement "4.5" "docs/workshop/step-1-chat.md" "docs/workshop/step-2-read.md" "docs/workshop/step-3-list.md" "docs/workshop/step-4-bash.md" "docs/workshop/step-5-edit.md" "docs/workshop/step-6-search.md"
check_requirement "5.1" "docs/api-reference/tools.md" "docs/api-reference/agent.md"
check_requirement "5.2" "docs/api-reference/tools.md"
check_requirement "5.3" "docs/api-reference/agent.md"
check_requirement "5.4" "docs/api-reference/types.md"
check_requirement "6.1" "docs/guides/creating-tools.md"
check_requirement "6.2" "docs/guides/creating-tools.md"
check_requirement "6.3" "docs/guides/creating-tools.md" "docs/guides/error-handling.md"
check_requirement "6.4" "docs/guides/creating-tools.md"
check_requirement "6.5" "docs/guides/creating-tools.md"
check_requirement "7.2" "docs/README.md"
check_requirement "7.3" "docs/README.md"
check_requirement "7.5" "docs/README.md"
check_requirement "8.1" "scripts/verify-documentation-coverage.sh"
check_requirement "8.5" "scripts/verify-code-sync.sh"
check_requirement "9.2" "docs/guides/best-practices.md"
check_requirement "9.3" "docs/guides/error-handling.md"
check_requirement "9.4" "docs/guides/best-practices.md"
check_requirement "10.1" "docs/troubleshooting/common-issues.md"
check_requirement "10.2" "docs/troubleshooting/debugging.md"
check_requirement "10.3" "docs/troubleshooting/common-issues.md"
check_requirement "10.4" "docs/troubleshooting/common-issues.md"

# 计算统计
missing_count=$(grep -c "^MISSING" "$TEMP_RESULTS" 2>/dev/null || echo "0")
missing_count=$(echo "$missing_count" | tr -d '\n')

# 计算覆盖率
if [ $total_requirements -gt 0 ]; then
    coverage=$((covered_requirements * 100 / total_requirements))
else
    coverage=0
fi

echo ""
echo "=========================================="
echo "验证结果"
echo "=========================================="
echo "总需求数: $total_requirements"
echo "已覆盖: $covered_requirements"
echo "未覆盖: ${missing_count}"
echo -e "覆盖率: ${GREEN}${coverage}%${NC}"
echo ""

# 生成报告
cat > "$REPORT_FILE" << EOF
# 文档覆盖率报告

生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 统计摘要

- **总需求数**: $total_requirements
- **已覆盖**: $covered_requirements
- **未覆盖**: $missing_count
- **覆盖率**: ${coverage}%

## 详细结果

### 已覆盖的需求

EOF

grep "^COVERED" "$TEMP_RESULTS" | while IFS='|' read -r status req_id docs; do
    echo "- 需求 $req_id: $docs" >> "$REPORT_FILE"
done

if [ "$missing_count" -gt 0 ]; then
    cat >> "$REPORT_FILE" << EOF

### 未覆盖的需求

EOF
    grep "^MISSING" "$TEMP_RESULTS" | while IFS='|' read -r status req_id docs; do
        echo "- 需求 $req_id: $docs" >> "$REPORT_FILE"
    done
fi

echo "报告已生成: $REPORT_FILE"
echo ""

# 返回状态
if [ "$missing_count" -eq 0 ]; then
    echo -e "${GREEN}✓ 所有需求都已覆盖！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ 存在未覆盖的需求${NC}"
    exit 1
fi
