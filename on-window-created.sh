#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# YABAI WINDOW CREATION HANDLER
# ═══════════════════════════════════════════════════════════════════════════
# This script is triggered when a new window is created.
# It automatically switches to the space where the window was created and
# focuses on it, making app space assignments feel more seamless.

WINDOW_ID="$YABAI_WINDOW_ID"
MAX_RETRIES=10
RETRY_DELAY=0.2

# Wait for the window to be fully ready (sometimes windows take a moment to initialize)
wait_for_window() {
    local retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        # Check if window exists and has a valid space
        WINDOW_INFO=$(yabai -m query --windows --window "$WINDOW_ID" 2>/dev/null)

        if [ -n "$WINDOW_INFO" ]; then
            WINDOW_SPACE=$(echo "$WINDOW_INFO" | jq -r '.space')
            IS_VISIBLE=$(echo "$WINDOW_INFO" | jq -r '."is-visible"')

            # Window is ready if it has a space and is visible
            if [ "$WINDOW_SPACE" != "null" ] && [ "$IS_VISIBLE" = "true" ]; then
                echo "$WINDOW_SPACE"
                return 0
            fi
        fi

        sleep $RETRY_DELAY
        retries=$((retries + 1))
    done

    # Timeout - return null
    echo "null"
    return 1
}

# Wait for window to be ready
WINDOW_SPACE=$(wait_for_window)

if [ "$WINDOW_SPACE" = "null" ]; then
    # Window not ready after retries, just balance and exit
    yabai -m space --balance 2>/dev/null
    exit 0
fi

# Get the currently focused space
CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')

# Only switch if the window was created on a different space
if [ "$WINDOW_SPACE" != "$CURRENT_SPACE" ]; then
    # Switch to the space where the window was created
    yabai -m space --focus "$WINDOW_SPACE" 2>/dev/null

    # Small delay to let the space switch complete
    sleep 0.1

    # Focus on the newly created window
    yabai -m window --focus "$WINDOW_ID" 2>/dev/null
fi

# Balance the space (existing behavior)
yabai -m space --balance 2>/dev/null

exit 0
