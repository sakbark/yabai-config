#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# YABAI DISPLAY CHANGE HANDLER
# ═══════════════════════════════════════════════════════════════════════════
# This script handles display add/remove events gracefully
# Waits for display configuration to stabilize then rebalances all spaces
# Also automatically fixes any windows that went offscreen during the change
# ═══════════════════════════════════════════════════════════════════════════

# Wait for display configuration to stabilize
sleep 3

# Balance all spaces now that displays are stable
for space in $(yabai -m query --spaces | jq '.[].index'); do
    yabai -m space "$space" --balance 2>/dev/null || true
done

# Fix any offscreen windows (common after display disconnect)
# Run in background to avoid blocking
~/.config/yabai/fix_offscreen_windows.sh >> /tmp/yabai-display-changes.log 2>&1 &

# Log the change
echo "[$(date)] Display configuration changed - rebalanced all spaces and fixed offscreen windows" >> /tmp/yabai-display-changes.log
