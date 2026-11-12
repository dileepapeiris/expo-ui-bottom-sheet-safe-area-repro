#!/bin/sh
# Launch the installed app on the simulator with the auto-run scenario and record it.
#   DISPLAY_ARG=--display=1 scripts/record.sh <simulator udid> <output name>
# The sheet opens by itself (App.js AUTORUN) and prints one RESULT line, which lands in metro.log.
UDID=$1; NAME=$2
BUNDLE=dev.dileepapeiris.sheetsaferepro
xcrun simctl terminate "$UDID" $BUNDLE 2>/dev/null
rm -f "media/$NAME.mp4"
START=$(wc -l < metro.log)
xcrun simctl io "$UDID" recordVideo $DISPLAY_ARG --codec h264 "media/$NAME.mp4" &
REC=$!
sleep 1
xcrun simctl launch "$UDID" $BUNDLE >/dev/null
sleep 14
xcrun simctl io "$UDID" screenshot $DISPLAY_ARG "media/$NAME-end.png" >/dev/null
kill -INT $REC; wait $REC 2>/dev/null
tail -n +"$((START + 1))" metro.log | grep "RESULT" | tee "media/$NAME-results.txt"
