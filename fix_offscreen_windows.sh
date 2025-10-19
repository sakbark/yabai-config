#!/usr/bin/env sh

echo "🔍 Checking for off-screen windows..."

# Get all displays and their dimensions
displays_json=$(yabai -m query --displays)
windows_json=$(yabai -m query --windows)

# Counter for found issues
issues_found=0

# Check each window
echo "$windows_json" | jq -r '.[] | @base64' | while IFS= read -r window_b64; do
    window_info=$(echo "$window_b64" | base64 -d)
    
    window_id=$(echo "$window_info" | jq -r '.id')
    window_x=$(echo "$window_info" | jq -r '.frame.x')
    window_y=$(echo "$window_info" | jq -r '.frame.y')
    window_w=$(echo "$window_info" | jq -r '.frame.w')
    window_h=$(echo "$window_info" | jq -r '.frame.h')
    window_display=$(echo "$window_info" | jq -r '.display')
    window_space=$(echo "$window_info" | jq -r '.space')
    window_app=$(echo "$window_info" | jq -r '.app')
    is_floating=$(echo "$window_info" | jq -r '.["is-floating"]')
    is_minimized=$(echo "$window_info" | jq -r '.["is-minimized"]')
    
    # Skip floating and minimized windows
    if [ "$is_floating" = "true" ] || [ "$is_minimized" = "true" ]; then
        continue
    fi
    
    # Get display dimensions for this window's display
    display_info=$(echo "$displays_json" | jq ".[] | select(.index == $window_display)")
    if [ -z "$display_info" ] || [ "$display_info" = "null" ]; then
        echo "⚠️  Window $window_id ($window_app) has invalid display reference"
        continue
    fi
    
    display_x=$(echo "$display_info" | jq -r '.frame.x')
    display_y=$(echo "$display_info" | jq -r '.frame.y')
    display_w=$(echo "$display_info" | jq -r '.frame.w')
    display_h=$(echo "$display_info" | jq -r '.frame.h')
    
    # Calculate window bounds (convert floating point to integer)
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
    
    # Check if window is off-screen (using stricter detection)
    visibility_threshold=50  # Allow only 50 pixels tolerance
    
    off_screen=false
    issue_desc=""
    
    # Check if window extends beyond display boundaries (more precise)
    # Check if window left edge is too far left of display
    if [ $window_x -lt $((display_x - visibility_threshold)) ]; then
        off_screen=true
        issue_desc="left edge too far left (x=$window_x, display starts at $display_x)"
    fi
    
    # Check if window right edge is too far right of display  
    if [ $window_right -gt $((display_right + visibility_threshold)) ]; then
        off_screen=true
        issue_desc="right edge too far right (right=$window_right, display ends at $display_right)"
    fi
    
    # Check if window top edge is too far up
    if [ $window_y -lt $((display_y - visibility_threshold)) ]; then
        off_screen=true
        issue_desc="top edge too far up (y=$window_y, display starts at $display_y)"
    fi
    
    # Check if window bottom edge is too far down
    if [ $window_bottom -gt $((display_bottom + visibility_threshold)) ]; then
        off_screen=true
        issue_desc="bottom edge too far down (bottom=$window_bottom, display ends at $display_bottom)"
    fi
    
    if [ "$off_screen" = "true" ]; then
        echo "🚨 Found off-screen window: $window_app (ID: $window_id) - $issue_desc"
        echo "   Window: x=$window_x, y=$window_y, w=$window_w, h=$window_h"
        echo "   Display: x=$display_x, y=$display_y, w=$display_w, h=$display_h"
        echo "   📍 Rebalancing space $window_space..."
        
        # Try multiple fix strategies
        echo "   🔧 Strategy 1: Focus and rebalance space..."
        yabai -m window --focus "$window_id" 2>/dev/null
        yabai -m space "$window_space" --balance 2>/dev/null
        
        sleep 0.3
        echo "   🔧 Strategy 2: Reset window position..."
        # Try to move window to its proper space/position
        yabai -m window "$window_id" --toggle float 2>/dev/null || true
        sleep 0.2
        yabai -m window "$window_id" --toggle float 2>/dev/null || true
        
        sleep 0.2
        echo "   🔧 Strategy 3: Final rebalance..."
        yabai -m space "$window_space" --balance 2>/dev/null
        
        issues_found=$((issues_found + 1))
    fi
done

if [ $issues_found -eq 0 ]; then
    echo "✅ No off-screen windows detected!"
else
    echo "🔧 Fixed $issues_found off-screen window(s)"
    echo "💡 If issues persist, try restarting the affected app or yabai"
fi