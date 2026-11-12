#!/bin/sh
# Swap the installed @expo/ui community BottomSheet (iOS) for one of the variants in variants/.
#   scripts/apply-variant.sh baseline|ignore-horizontal
# The variants are copies of node_modules/@expo/ui/build/community/bottom-sheet/BottomSheet.ios.js
# (58.0.28); ignore-horizontal appends `ignoreSafeArea({ edges: 'horizontal' })` to the content
# Group's modifiers, the change the issue proposes. JS only, so no native rebuild is needed.
set -e
cd "$(dirname "$0")/.."
cp "variants/BottomSheet.ios.$1.js" node_modules/@expo/ui/build/community/bottom-sheet/BottomSheet.ios.js
echo "applied $1"
