#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# YABAI APP ACTIVATION HANDLER
# ═══════════════════════════════════════════════════════════════════════════
# This script is triggered when an app is activated (brought to front).
# It automatically switches to the space where the app's window is located,
# making it seamless to switch between already-running apps.

APP_PID="$YABAI_PROCESS_ID"

# Get any window of the activated app (prioritize visible, then any)
# We check both visible and non-visible because the activation happens before focus
WINDOW_INFO=$(yabai -m query --windows | jq -r --arg pid "$APP_PID" '
  [.[] | select(.pid == ($pid | tonumber))] |
  (map(select(."is-visible" == true)) + map(select(."is-minimized" == false))) |
  unique_by(.id) |
  first |
  @json
')

if [ -z "$WINDOW_INFO" ]; then
    # No window found, exit silently
    exit 0
fi

# Extract window details
WINDOW_SPACE=$(echo "$WINDOW_INFO" | jq -r '.space')
WINDOW_ID=$(echo "$WINDOW_INFO" | jq -r '.id')
IS_FLOATING=$(echo "$WINDOW_INFO" | jq -r '."is-floating"')
IS_STICKY=$(echo "$WINDOW_INFO" | jq -r '."is-sticky"')

# Get current space
CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')

# Skip if window is sticky (it follows us everywhere anyway)
if [ "$IS_STICKY" = "true" ]; then
    exit 0
fi

# Only switch if the window is on a different space
if [ "$WINDOW_SPACE" != "null" ] && [ "$WINDOW_SPACE" != "$CURRENT_SPACE" ]; then
    # Switch to the space where the window is located
    yabai -m space --focus "$WINDOW_SPACE" 2>/dev/null

    # Focus on the window
    yabai -m window --focus "$WINDOW_ID" 2>/dev/null
fi

exit 0
