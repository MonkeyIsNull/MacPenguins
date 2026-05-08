#!/bin/bash
#
# MacPenguins Launcher Script
#

echo "Starting MacPenguins..."
echo "Working directory: $(pwd)"

# Check if sprites exist
if [ -d "MacPenguins/Themes/Penguins" ]; then
    echo "[OK] Found theme directory with $(ls MacPenguins/Themes/Penguins/*.png 2>/dev/null | wc -l) PNG files"
else
    echo "[ERR] Theme directory not found"
    echo "Themes should be in: MacPenguins/Themes/Penguins/"
fi

echo ""
echo "Launching MacPenguins..."
echo "   - Watch for overlay windows on your displays"
echo "   - Penguins should start falling from the top"
echo "   - Press Ctrl+C to stop"
echo ""

swift run MacPenguins
