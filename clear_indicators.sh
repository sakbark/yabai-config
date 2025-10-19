#!/bin/bash

# Emergency script to clear orange insertion indicators
echo "🧹 Clearing all insertion indicators..."

# Method 1: Clear current window insertion
yabai -m window --insert cancel 2>/dev/null || true

# Method 2: Clear space insertion
yabai -m space --insert cancel 2>/dev/null || true

# Method 3: Focus all windows and clear their insertion points
windows=$(yabai -m query --windows --space | jq -r '.[] | select(.["is-floating"] == false) | .id')
for window_id in $windows; do
    yabai -m window "$window_id" --focus 2>/dev/null || true
    yabai -m window "$window_id" --insert cancel 2>/dev/null || true
done

# Method 4: Balance space to refresh layout
yabai -m space --balance 2>/dev/null || true

echo "✅ Insertion indicator cleanup complete!"
echo "If orange blocks persist, try running this script multiple times."