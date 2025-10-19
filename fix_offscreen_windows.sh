#!/usr/bin/env sh

# ═══════════════════════════════════════════════════════════════════════════
# FIX OFFSCREEN WINDOWS - COMPREHENSIVE VERSION
# ═══════════════════════════════════════════════════════════════════════════
# Detects and fixes windows positioned offscreen (negative coordinates or
# beyond display boundaries). Handles both tiled AND floating windows.

echo "🔍 Scanning for offscreen windows..."

# Get all displays and windows
displays_json=$(yabai -m query --displays)
windows_json=$(yabai -m query --windows)

# Counter for found issues
fixed_count=0
skipped_count=0

# Get main display bounds as fallback safe zone
main_display=$(echo "$displays_json" | jq '.[] | select(.index == 1)')
safe_x=$(echo "$main_display" | jq -r '.frame.x + 100')
safe_y=$(echo "$main_display" | jq -r '.frame.y + 100')

# Check each window (using base64 to handle special characters)
echo "$windows_json" | jq -r '.[] | @base64' | while IFS= read -r window_b64; do
    window_info=$(echo "$window_b64" | base64 -d 2>/dev/null)

    # Skip if decoding failed
    [ -z "$window_info" ] && continue

    window_id=$(echo "$window_info" | jq -r '.id')
    window_x=$(echo "$window_info" | jq -r '.frame.x')
    window_y=$(echo "$window_info" | jq -r '.frame.y')
    window_w=$(echo "$window_info" | jq -r '.frame.w')
    window_h=$(echo "$window_info" | jq -r '.frame.h')
    window_display=$(echo "$window_info" | jq -r '.display')
    window_app=$(echo "$window_info" | jq -r '.app')
    is_floating=$(echo "$window_info" | jq -r '."is-floating"')
    is_minimized=$(echo "$window_info" | jq -r '."is-minimized"')
    is_sticky=$(echo "$window_info" | jq -r '."is-sticky"')
    can_move=$(echo "$window_info" | jq -r '."can-move"')
    window_role=$(echo "$window_info" | jq -r '.role')

    # Skip minimized windows
    if [ "$is_minimized" = "true" ]; then
        continue
    fi

    # Skip windows that can't be moved
    if [ "$can_move" = "false" ]; then
        continue
    fi

    # Get display dimensions for this window's display
    display_info=$(echo "$displays_json" | jq ".[] | select(.index == $window_display)")
    if [ -z "$display_info" ] || [ "$display_info" = "null" ]; then
        echo "⚠️  $window_app (ID: $window_id) - invalid display reference"
        skipped_count=$((skipped_count + 1))
        continue
    fi

    display_x=$(echo "$display_info" | jq -r '.frame.x')
    display_y=$(echo "$display_info" | jq -r '.frame.y')
    display_w=$(echo "$display_info" | jq -r '.frame.w')
    display_h=$(echo "$display_info" | jq -r '.frame.h')

    # Convert to integers
    window_x=$(printf "%.0f" "$window_x")
    window_y=$(printf "%.0f" "$window_y")
    window_w=$(printf "%.0f" "$window_w")
    window_h=$(printf "%.0f" "$window_h")
    display_x=$(printf "%.0f" "$display_x")
    display_y=$(printf "%.0f" "$display_y")
    display_w=$(printf "%.0f" "$display_w")
    display_h=$(printf "%.0f" "$display_h")

    window_right=$((window_x + window_w))
    window_bottom=$((window_y + window_h))
    display_right=$((display_x + display_w))
    display_bottom=$((display_y + display_h))

    # Determine if window is offscreen
    # For floating windows (including popovers), we're stricter about negative coords
    off_screen=false
    new_x=""
    new_y=""
    issue=""

    # Check for completely offscreen (negative or way outside display)
    if [ $window_x -lt $display_x ]; then
        off_screen=true
        new_x=$((display_x + 100))
        issue="left edge offscreen (x=$window_x)"
    fi

    if [ $window_y -lt $display_y ]; then
        off_screen=true
        new_y=$((display_y + 50))
        issue="$issue top edge offscreen (y=$window_y)"
    fi

    # Check if completely off the right side
    if [ $window_x -gt $display_right ]; then
        off_screen=true
        new_x=$((display_right - window_w - 100))
        issue="$issue completely right of display"
    fi

    # Check if completely off the bottom
    if [ $window_y -gt $display_bottom ]; then
        off_screen=true
        new_y=$((display_bottom - window_h - 100))
        issue="$issue completely below display"
    fi

    # If offscreen, fix it
    if [ "$off_screen" = "true" ]; then
        echo "🚨 FOUND: $window_app (ID: $window_id, Role: $window_role)"
        echo "   Issue: $issue"
        echo "   Current: x=$window_x, y=$window_y"

        # Determine new position
        [ -z "$new_x" ] && new_x=$window_x
        [ -z "$new_y" ] && new_y=$window_y

        echo "   Moving to: x=$new_x, y=$new_y"

        # For floating windows, use direct positioning
        if [ "$is_floating" = "true" ]; then
            yabai -m window "$window_id" --move "abs:$new_x:$new_y" 2>/dev/null && \
                echo "   ✅ Moved successfully" || \
                echo "   ❌ Failed to move"
        else
            # For tiled windows, toggle float, move, toggle back
            yabai -m window "$window_id" --toggle float 2>/dev/null
            sleep 0.1
            yabai -m window "$window_id" --move "abs:$new_x:$new_y" 2>/dev/null
            sleep 0.1
            yabai -m window "$window_id" --toggle float 2>/dev/null && \
                echo "   ✅ Fixed and re-tiled" || \
                echo "   ⚠️  Partially fixed"
        fi

        fixed_count=$((fixed_count + 1))
    fi
done

echo ""
echo "═══════════════════════════════════════"
if [ $fixed_count -eq 0 ]; then
    echo "✅ No offscreen windows found!"
else
    echo "🔧 Fixed $fixed_count offscreen window(s)"
fi

if [ $skipped_count -gt 0 ]; then
    echo "⏭️  Skipped $skipped_count window(s) (unmovable or invalid)"
fi
echo "═══════════════════════════════════════"
