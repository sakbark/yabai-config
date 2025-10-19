#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# YABAI DISPLAY CHANGE HANDLER
# ═══════════════════════════════════════════════════════════════════════════
# This script handles display add/remove events gracefully
# Waits for display configuration to stabilize then rebalances all spaces
# ═══════════════════════════════════════════════════════════════════════════

# Wait for display configuration to stabilize
sleep 3

# Balance all spaces now that displays are stable
for space in $(yabai -m query --spaces | jq '.[].index'); do
    yabai -m space "$space" --balance 2>/dev/null || true
done

# Log the change
echo "[$(date)] Display configuration changed - rebalanced all spaces" >> /tmp/yabai-display-changes.log
