#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# YABAI WINDOW CREATION HANDLER
# ═══════════════════════════════════════════════════════════════════════════
# This script is triggered when a new window is created.
# It automatically switches to the space where the window was created and
# focuses on it, making app space assignments feel more seamless.

WINDOW_ID="$YABAI_WINDOW_ID"

# Get the space where the window was created
WINDOW_SPACE=$(yabai -m query --windows --window "$WINDOW_ID" | jq -r '.space')

# Get the currently focused space
CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')

# Only switch if the window was created on a different space
if [ "$WINDOW_SPACE" != "null" ] && [ "$WINDOW_SPACE" != "$CURRENT_SPACE" ]; then
    # Switch to the space where the window was created
    yabai -m space --focus "$WINDOW_SPACE" 2>/dev/null

    # Focus on the newly created window
    yabai -m window --focus "$WINDOW_ID" 2>/dev/null
fi

# Balance the space (existing behavior)
yabai -m space --balance 2>/dev/null

exit 0
