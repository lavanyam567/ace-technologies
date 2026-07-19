#!/bin/bash
set -e

# Inject GITHUB_PATH into PATH so node binaries are available
if [ -f "$GITHUB_PATH" ]; then
    while IFS= read -r line; do
        export PATH="$line:$PATH"
    done < "$GITHUB_PATH"
fi

echo "Installing APK onto emulator..."
if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
    adb install -r "$APK_PATH"
else
    echo "Warning: APK_PATH is not set or file does not exist. Tests may fail if they rely on the app."
fi

echo "Starting Appium Server..."
appium --log-level warn > /tmp/appium.log 2>&1 &
APPIUM_PID=$!

echo "Waiting for Appium to respond on port 4723..."
timeout 30 bash -c 'until curl -s http://127.0.0.1:4723/status > /dev/null; do sleep 1; done' || (echo "Appium failed to start"; exit 1)
echo "Appium started."

echo "Executing Appium Tests..."
# Define the path to tests relative to the frontend directory
npx mocha appium_tests/tests/mega_android_1100.test.js --reporter ./appium_tests/utils/xlsxReporter.js

kill $APPIUM_PID
