#!/bin/sh
# Swap the installed @expo/ui community BottomSheet (iOS) for one of the variants in variants/.
#   scripts/apply-variant.sh baseline|ignore-horizontal|pr
# The variants are copies of node_modules/@expo/ui/build/community/bottom-sheet/BottomSheet.ios.js
# (58.0.28); ignore-horizontal appends `ignoreSafeArea({ edges: 'horizontal' })` to the content
# Group's modifiers, the change the issue proposes; pr adds the `modifiers` prop of the fix PR and
# makes App.js pass the same modifier through it. JS only, so no native rebuild is needed.
set -e
cd "$(dirname "$0")/.."
cp "variants/BottomSheet.ios.$1.js" node_modules/@expo/ui/build/community/bottom-sheet/BottomSheet.ios.js
if [ "$1" = pr ]; then FLAG=true; else FLAG=false; fi
sed -i '' "s/^const USE_MODIFIERS_PROP = .*/const USE_MODIFIERS_PROP = $FLAG;/" App.js
echo "applied $1"
