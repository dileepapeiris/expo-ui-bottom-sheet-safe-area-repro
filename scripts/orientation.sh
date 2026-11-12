#!/bin/sh
# Restrict the app to one orientation so it launches that way on any simulator, then rebuild.
#   scripts/orientation.sh landscape|portrait <simulator udid>
# DeviceHub has no rotate command this script could drive, so the app pins itself instead.
set -e
cd "$(dirname "$0")/.."
P=ios/expouibottomsheetsafearearepro/Info.plist
/usr/libexec/PlistBuddy -c "Delete :UISupportedInterfaceOrientations" "$P"
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations array" "$P"
if [ "$1" = landscape ]; then
  /usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationLandscapeRight" "$P"
else
  /usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationPortrait" "$P"
fi
/usr/libexec/PlistBuddy -c "Print :UISupportedInterfaceOrientations" "$P"
scripts/build.sh "$2"
