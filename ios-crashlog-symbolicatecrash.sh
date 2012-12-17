#!/bin/sh

if [ $# -ne 2 ]
then
  echo "Usage: Copy 'app_name'.app and 'app_name'.app.dSYM into `dirname $0` and run"
  echo "`basename $0` app_name crash_file.crash"
  exit 1
fi

CRASH=$2
APP=$1
DEVELOPER_DIR=`xcode-select --print-path`
export DEVELOPER_DIR
SYMBOLICATE_PATH=${DEVELOPER_DIR}/Platforms/iPhoneOS.platform/Developer/Library//PrivateFrameworks/DTDeviceKit.framework/Versions/A/Resources/symbolicatecrash

set -e

CRASH_UUID=`grep --after-context=2 "Binary Images:" "${CRASH}" | grep "${APP}" | grep -o "<.*>" | sed -E "s/<(.*)>/\1/"`
echo "Found crash UUID: \"${CRASH_UUID}\""

APP_UUID=`dwarfdump --uuid ${APP}.app/${APP} | cut -d ' ' -f 2`
echo "Found app UUID: \"${APP_UUID}\""

DYSYM_UUID=`dwarfdump --uuid ${APP}.app.dSYM  | cut -d ' ' -f 2`
echo "Found dsym UUID: \"${DYSYM_UUID}\""

echo "-----------------------------------"
echo "UUID's must match ${CRASH_UUID} ${APP_UUID} ${DYSYM_UUID}"
echo "-----------------------------------"

mdimport `pwd`
DYSYM_SPOTLIGHT_LOCATION=`mdfind "com_apple_xcode_dsym_uuids = \"${DYSYM_UUID}\""`
echo "$DYSYM_SPOTLIGHT_LOCATION"

if [ -z "$DYSYM_SPOTLIGHT_LOCATION" ]; then
    echo "DSYM with UUID \"${DYSYM_UUID}\" not found in spotlight, symbolication will fail"
    exit 1
fi

"${SYMBOLICATE_PATH}" "${CRASH}"
