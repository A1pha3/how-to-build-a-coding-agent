#!/bin/bash

# 主验证脚本 - 运行所有文档验证检查

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "文档系统完整验证"
echo "=========================================="
echo ""

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 验证结果
declare -a results=()
declare -a failed_checks=()

# 运行单个验证脚本
run_check() {
    local name="$1"
    local script="$2"
    
    echo -e "${BLUE}>>> 运行: $name${NC}"
    echo ""
    
    if "$SCRIPT_DIR/$script" 2>&1; then
        results+=("PASS|$name")
        echo ""
        echo -e "${GREEN}✓ $name 通过${NC}"
    else
        results+=("FAIL|$name")
        failed_checks+=("$name")
        echo ""
        echo -e "${RED}✗ $name 失败${NC}"
    fi
    
    echo ""
    echo "=========================================="
    echo ""
}

# 运行所有验证
run_check "文档完整性验证" "verify-documentation-coverage.sh"
run_check "代码同步验证" "verify-code-sync.sh"
run_check "链接有效性验证" "verify-links.sh"
run_check "命名规范验证" "verify-naming.sh"
run_check "模板一致性验证" "verify-template.sh"

# 统计结果
total_checks=${#results[@]}
passed_checks=$((total_checks - ${#failed_checks[@]}))

echo ""
echo "=========================================="
echo "验证总结"
echo "=========================================="
echo ""
echo "总检查项: $total_checks"
echo -e "通过: ${GREEN}$passed_checks${NC}"
echo -e "失败: ${RED}${#failed_checks[@]}${NC}"
echo ""

# 显示详细结果
for result in "${results[@]}"; do
    IFS='|' read -r status name <<< "$result"
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $name"
    else
        echo -e "${RED}✗${NC} $name"
    fi
done

echo ""
echo "=========================================="
echo ""

# 生成的报告文件
echo "生成的报告文件:"
echo "  - docs/coverage-report.md"
echo "  - docs/code-sync-report.md"
echo "  - docs/links-report.md"
echo "  - docs/naming-report.md"
echo "  - docs/template-report.md"
echo ""

# 返回状态
if [ ${#failed_checks[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ 所有验证都通过！${NC}"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠ 有 ${#failed_checks[@]} 项验证失败${NC}"
    echo ""
    echo "失败的检查:"
    for check in "${failed_checks[@]}"; do
        echo "  - $check"
    done
    echo ""
    exit 1
fi
