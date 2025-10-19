#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# YABAI APP ACTIVATION HANDLER
# ═══════════════════════════════════════════════════════════════════════════
# This script is triggered when an app is activated (brought to front).
# It automatically switches to the space where the app's window is located,
# making it seamless to switch between already-running apps.

APP_PID="$YABAI_PROCESS_ID"
MAX_RETRIES=15
RETRY_DELAY=0.3

# Wait for app to have a visible window (it might be launching)
wait_for_app_window() {
    local retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        # Get any window of the activated app (prioritize visible, then non-minimized)
        WINDOW_INFO=$(yabai -m query --windows | jq -r --arg pid "$APP_PID" '
          [.[] | select(.pid == ($pid | tonumber))] |
          (map(select(."is-visible" == true)) + map(select(."is-minimized" == false))) |
          unique_by(.id) |
          first |
          @json
        ')

        if [ -n "$WINDOW_INFO" ] && [ "$WINDOW_INFO" != "null" ]; then
            # Check if window has required properties
            WINDOW_SPACE=$(echo "$WINDOW_INFO" | jq -r '.space')
            WINDOW_ID=$(echo "$WINDOW_INFO" | jq -r '.id')

            if [ "$WINDOW_SPACE" != "null" ] && [ "$WINDOW_ID" != "null" ]; then
                # Window found and ready
                echo "$WINDOW_INFO"
                return 0
            fi
        fi

        sleep $RETRY_DELAY
        retries=$((retries + 1))
    done

    # No window found after retries
    return 1
}

# Wait for the app to have a window
WINDOW_INFO=$(wait_for_app_window)

if [ -z "$WINDOW_INFO" ]; then
    # No window found, exit silently (might be a menubar-only app)
    exit 0
fi

# Extract window details
WINDOW_SPACE=$(echo "$WINDOW_INFO" | jq -r '.space')
WINDOW_ID=$(echo "$WINDOW_INFO" | jq -r '.id')
IS_STICKY=$(echo "$WINDOW_INFO" | jq -r '."is-sticky"')

# Get current space
CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')

# Skip if window is sticky (it follows us everywhere anyway)
if [ "$IS_STICKY" = "true" ]; then
    exit 0
fi

# Only switch if the window is on a different space
if [ "$WINDOW_SPACE" != "$CURRENT_SPACE" ]; then
    # Switch to the space where the window is located
    yabai -m space --focus "$WINDOW_SPACE" 2>/dev/null

    # Small delay to let the space switch complete
    sleep 0.1

    # Focus on the window
    yabai -m window --focus "$WINDOW_ID" 2>/dev/null
fi

exit 0
