#!/bin/sh
# Incremental debug build of the prebuilt iOS project and install on a simulator, without the
# deep link that `expo run:ios` opens at the end (it leaves an "Open in app?" alert on the simulator).
#   scripts/build.sh <simulator udid>
# Pods must be installed (npx expo prebuild -p ios, or a previous npx expo run:ios).
UDID=$1
C=$HOME/Library/Caches/ReactNative
export RCT_USE_LOCAL_RN_DEP=$C/reactnative-dependencies-0.88.0-debug.tar.gz
export RCT_TESTONLY_RNCORE_TARBALL_PATH=$C/reactnative-core-0.88.0-debug.tar.gz
export HERMES_ENGINE_TARBALL_PATH=$C/hermes-ios-260318099.0.4-debug.tar.gz
WS=$(ls -d ios/*.xcworkspace | head -1)
SCHEME=$(basename "$WS" .xcworkspace)
xcodebuild -workspace "$WS" -scheme "$SCHEME" -configuration Debug -destination "id=$UDID" build 2>&1 \
  | tee .expo/xcodebuild.log | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
APP=$(grep -m1 -o '/[^ ]*/Build/Products/Debug-iphonesimulator/[^/]*\.app' .expo/xcodebuild.log | head -1)
[ -d "$APP" ] || { echo "no app found in the build log"; exit 1; }
xcrun simctl install "$UDID" "$APP" && echo "installed $APP"
