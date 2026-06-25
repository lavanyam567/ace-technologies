#!/bin/bash
set -e

echo "Starting CI Appium Test Runner..."

# Inject GITHUB_PATH to ensure Node binaries are available inside emulator runner
if [ -f "$GITHUB_PATH" ]; then
  echo "Loading GITHUB_PATH into current PATH..."
  while IFS= read -r line; do
    export PATH="$line:$PATH"
  done < "$GITHUB_PATH"
fi

if [ -z "$APK_PATH" ]; then
  echo "Error: APK_PATH environment variable is not set."
  exit 1
fi

echo "Installing APK onto emulator from: $APK_PATH"
adb install -r "$APK_PATH"

echo "Starting Appium Server in background..."
npx appium --log-level warn > /tmp/appium.log 2>&1 &
APPIUM_PID=$!

echo "Waiting for Appium to respond on port 4723..."
timeout 60 bash -c 'until curl -s http://127.0.0.1:4723/status > /dev/null; do sleep 2; done'
echo "Appium server is up."

echo "Installing NPM dependencies..."
npm install xlsx --no-save

echo "Executing Appium E2E test suite..."
# Assuming `npx mocha tests/mega_android_300.test.js` or similar based on Prompt 3
npx mocha tests/mega_android_300.test.js --reporter ./utils/xlsxReporter.js

echo "Generating HTML report..."
node scripts/generate-html-report.js

echo "Appending Summary to GitHub Actions..."
node scripts/generate-summary.js

echo "Shutting down Appium..."
kill $APPIUM_PID || true
echo "Test execution complete."
