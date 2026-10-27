#!/bin/sh
# Rebuild the Orion icons for Neovim from the Orion IDE's icon theme:
#   1. pico.py        SVGs -> simple filled shapes (pico/)
#   2. build_font.py  shapes -> color glyphs in "JetBrainsMono Orion" (out/)
#   3. gen_lua.py     theme mappings -> lua/orion_icons/data.lua
#   4. installs the fonts to ~/Library/Fonts
# Needs JetBrainsMono Nerd Font Mono installed and the Orion repo at
# ~/Documents/Amphion/orion. Run: sh build.sh
set -e
cd "$(dirname "$0")"
[ -d venv ] || { python3 -m venv venv && ./venv/bin/pip install -q fonttools picosvg; }
./venv/bin/python pico.py
./venv/bin/python build_font.py out
./venv/bin/python gen_lua.py out/icons.json ../../lua/orion_icons/data.lua
cp out/JetBrainsMonoOrion-*.ttf ~/Library/Fonts/
echo "Done. Restart Terminal windows / Neovim to pick up changes."
