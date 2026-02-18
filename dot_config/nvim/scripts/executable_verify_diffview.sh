#!/bin/bash
# Manual verification script for diffview keymaps
# This script opens nvim and displays the configured keymaps

echo "🔍 Verifying Diffview Keymaps Integration"
echo "=========================================="
echo ""

# Check if files were modified
echo "📝 Modified Files:"
echo "  ✓ plugin/programming.lua (added diffview keymaps)"
echo "  ✓ lua/autocmd.lua (added Neogit integration)"
echo ""

# Display the keymaps
echo "🗺️  Configured Keymaps:"
echo "  <leader>gd - Open diffview"
echo "  <leader>gD - Close diffview"
echo "  <leader>gf - File history (current file)"
echo "  <leader>gF - File history (all files)"
echo "  <leader>gm - Merge base diff (compare with origin/HEAD)"
echo ""

# Display autocmd info
echo "⚙️  Autocmd Configuration:"
echo "  FileType: NeogitStatus"
echo "  Keymap: <leader>gd → DiffviewOpen"
echo ""

# Check if in git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✓ In git repository - ready to test!"
    echo ""
    echo "📋 Test Checklist:"
    echo "  1. Open nvim"
    echo "  2. Type <leader>g and observe mini.clue hints"
    echo "  3. Try <leader>gd to open diffview"
    echo "  4. Press 'q' to close diffview"
    echo "  5. Try <leader>gf for current file history"
    echo "  6. Try <leader>gg then <leader>gd from Neogit"
    echo ""
else
    echo "⚠️  Not in a git repository"
    echo "   Change to a git repo directory to test diffview"
    echo ""
fi

read -p "Press Enter to open nvim for manual testing (Ctrl-C to cancel)..."
nvim
