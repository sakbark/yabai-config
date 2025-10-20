#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# YABAI SCRIPTS DEBUG & VALIDATION
# ═══════════════════════════════════════════════════════════════════════════
# Comprehensive debugging and validation of all yabai automation scripts
# Tests for common issues, edge cases, and potential bugs

set -e

SCRIPT_DIR="/Users/saady/.config/yabai"
REPORT_FILE="/tmp/yabai-debug-report-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "═══════════════════════════════════════════════════════════════"
echo "YABAI SCRIPTS DEBUG & VALIDATION REPORT"
echo "═══════════════════════════════════════════════════════════════"
echo "Date: $(date)"
echo "Report will be saved to: $REPORT_FILE"
echo ""

# Redirect all output to both console and log file
exec > >(tee -a "$REPORT_FILE") 2>&1

# ═══════════════════════════════════════════════════════════════════════════
# 1. DEPENDENCY CHECKS
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "1. CHECKING DEPENDENCIES"
echo "──────────────────────────────────────────────────────────────"

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed ($(command -v $1))"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        return 1
    fi
}

DEPS_OK=true
check_command yabai || DEPS_OK=false
check_command jq || DEPS_OK=false
check_command skhd || DEPS_OK=false

if [ "$DEPS_OK" = false ]; then
    echo -e "${RED}ERROR: Missing dependencies!${NC}"
    exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 2. YABAI SERVICE STATUS
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "2. YABAI SERVICE STATUS"
echo "──────────────────────────────────────────────────────────────"

if pgrep -x yabai > /dev/null; then
    echo -e "${GREEN}✓${NC} yabai is running (PID: $(pgrep -x yabai))"
    yabai --version
else
    echo -e "${RED}✗${NC} yabai is NOT running"
fi

if pgrep -x skhd > /dev/null; then
    echo -e "${GREEN}✓${NC} skhd is running (PID: $(pgrep -x skhd))"
else
    echo -e "${RED}✗${NC} skhd is NOT running"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 3. SCRIPT FILE CHECKS
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "3. SCRIPT FILE CHECKS"
echo "──────────────────────────────────────────────────────────────"

SCRIPTS=(
    "on-window-created.sh"
    "on-app-activated.sh"
    "fix_offscreen_windows.sh"
    "handle-display-change.sh"
    "clear_indicators.sh"
)

for script in "${SCRIPTS[@]}"; do
    script_path="$SCRIPT_DIR/$script"

    echo "Checking: $script"

    # Check existence
    if [ ! -f "$script_path" ]; then
        echo -e "  ${RED}✗${NC} File not found!"
        continue
    fi

    # Check executable permission
    if [ -x "$script_path" ]; then
        echo -e "  ${GREEN}✓${NC} Executable permissions OK"
    else
        echo -e "  ${YELLOW}⚠${NC} NOT executable (chmod +x needed)"
    fi

    # Check shebang
    shebang=$(head -n 1 "$script_path")
    if [[ "$shebang" == "#!/usr/bin/env bash" ]] || [[ "$shebang" == "#!/usr/bin/env sh" ]]; then
        echo -e "  ${GREEN}✓${NC} Shebang correct: $shebang"
    else
        echo -e "  ${YELLOW}⚠${NC} Shebang: $shebang (recommend #!/usr/bin/env bash)"
    fi

    # Check for common issues
    if grep -q "set -e" "$script_path"; then
        echo -e "  ${YELLOW}⚠${NC} Uses 'set -e' (may exit on any error)"
    fi

    # Check file size
    lines=$(wc -l < "$script_path")
    echo -e "  ${GREEN}ℹ${NC} $lines lines"

    echo ""
done

# ═══════════════════════════════════════════════════════════════════════════
# 4. YABAI SIGNALS CHECK
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "4. YABAI SIGNALS CONFIGURATION"
echo "──────────────────────────────────────────────────────────────"

echo "Registered signals:"
yabai -m signal --list | jq -r '.[] | "\(.event) → \(.action)"' | head -10

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 5. FUNCTIONAL TESTS
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "5. FUNCTIONAL TESTS"
echo "──────────────────────────────────────────────────────────────"

# Test 1: Query windows works
echo "Test 1: Can query windows"
if yabai -m query --windows > /dev/null 2>&1; then
    window_count=$(yabai -m query --windows | jq 'length')
    echo -e "${GREEN}✓${NC} Successfully queried windows (found: $window_count)"
else
    echo -e "${RED}✗${NC} Failed to query windows"
fi

# Test 2: Query spaces works
echo "Test 2: Can query spaces"
if yabai -m query --spaces > /dev/null 2>&1; then
    space_count=$(yabai -m query --spaces | jq 'length')
    echo -e "${GREEN}✓${NC} Successfully queried spaces (found: $space_count)"
else
    echo -e "${RED}✗${NC} Failed to query spaces"
fi

# Test 3: Query displays works
echo "Test 3: Can query displays"
if yabai -m query --displays > /dev/null 2>&1; then
    display_count=$(yabai -m query --displays | jq 'length')
    echo -e "${GREEN}✓${NC} Successfully queried displays (found: $display_count)"
else
    echo -e "${RED}✗${NC} Failed to query displays"
fi

# Test 4: Check for offscreen windows
echo "Test 4: Offscreen window detection"
bash "$SCRIPT_DIR/fix_offscreen_windows.sh" 2>&1 | grep -E "✅|🚨" | head -3

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 6. PERFORMANCE TESTS
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "6. PERFORMANCE TESTS"
echo "──────────────────────────────────────────────────────────────"

# Test script execution times
for script in "${SCRIPTS[@]}"; do
    if [[ "$script" == "fix_offscreen_windows.sh" ]]; then
        echo "Testing: $script"
        start=$(date +%s%N)
        bash "$SCRIPT_DIR/$script" > /dev/null 2>&1
        end=$(date +%s%N)
        elapsed=$(( (end - start) / 1000000 ))
        echo -e "  Execution time: ${elapsed}ms"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 7. LOG FILE CHECKS
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "7. LOG FILE CHECKS"
echo "──────────────────────────────────────────────────────────────"

LOG_FILES=(
    "/tmp/yabai-display-changes.log"
    "/tmp/yabai_saady.out.log"
    "/tmp/yabai_saady.err.log"
)

for log in "${LOG_FILES[@]}"; do
    if [ -f "$log" ]; then
        size=$(du -h "$log" | cut -f1)
        lines=$(wc -l < "$log")
        echo -e "${GREEN}✓${NC} $log ($size, $lines lines)"

        if [ -s "$log" ]; then
            echo "  Last 3 entries:"
            tail -3 "$log" | sed 's/^/    /'
        fi
    else
        echo -e "${YELLOW}ℹ${NC} $log (not found - will be created when needed)"
    fi
    echo ""
done

# ═══════════════════════════════════════════════════════════════════════════
# 8. COMMON ISSUES CHECK
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "8. CHECKING FOR COMMON ISSUES"
echo "──────────────────────────────────────────────────────────────"

# Check for stuck/orphaned processes
orphaned=$(pgrep -f "yabai.*sh" | wc -l)
if [ "$orphaned" -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} Found $orphaned yabai script processes"
    pgrep -f "yabai.*sh" -l
else
    echo -e "${GREEN}✓${NC} No orphaned script processes"
fi

# Check for large log files (>10MB)
for log in "${LOG_FILES[@]}"; do
    if [ -f "$log" ]; then
        size_bytes=$(stat -f%z "$log" 2>/dev/null || echo 0)
        if [ "$size_bytes" -gt 10485760 ]; then
            echo -e "${YELLOW}⚠${NC} Large log file: $log ($(du -h "$log" | cut -f1))"
            echo "  Consider rotating or clearing this log"
        fi
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 9. EDGE CASE TESTS
# ═══════════════════════════════════════════════════════════════════════════

echo "──────────────────────────────────────────────────────────────"
echo "9. EDGE CASE TESTS"
echo "──────────────────────────────────────────────────────────────"

# Test: What happens with no windows?
echo "Test: Behavior with minimal windows"
window_count=$(yabai -m query --windows | jq 'length')
if [ "$window_count" -lt 5 ]; then
    echo -e "${YELLOW}⚠${NC} Only $window_count windows open (low count for testing)"
else
    echo -e "${GREEN}✓${NC} $window_count windows open (good for testing)"
fi

# Test: Check for windows on invalid spaces
echo "Test: Windows on invalid spaces"
invalid_spaces=$(yabai -m query --windows | jq '[.[] | select(.space == null or .space == 0)] | length')
if [ "$invalid_spaces" -gt 0 ]; then
    echo -e "${RED}✗${NC} Found $invalid_spaces windows with invalid space assignment"
else
    echo -e "${GREEN}✓${NC} No windows with invalid space assignment"
fi

# Test: Check for windows with invalid display
echo "Test: Windows on invalid displays"
invalid_displays=$(yabai -m query --windows | jq '[.[] | select(.display == null or .display == 0)] | length')
if [ "$invalid_displays" -gt 0 ]; then
    echo -e "${RED}✗${NC} Found $invalid_displays windows with invalid display assignment"
else
    echo -e "${GREEN}✓${NC} No windows with invalid display assignment"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 10. SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Report saved to: $REPORT_FILE"
echo ""
echo "Next steps:"
echo "  1. Review any ${RED}✗${NC} (failed) or ${YELLOW}⚠${NC} (warning) items above"
echo "  2. Fix any issues found"
echo "  3. Re-run this debug script to verify fixes"
echo ""
echo "To view the full report:"
echo "  cat $REPORT_FILE"
echo ""
echo "═══════════════════════════════════════════════════════════════"
