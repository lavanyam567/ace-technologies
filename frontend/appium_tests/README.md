# Ace Technologies - Appium Android Testing Suite

This folder contains the Android mobile automation suite for Ace Technologies
using Appium and WebdriverIO. The suite now generates `301` cases across
functional, UI/UX, compatibility, and end-to-end coverage, and it writes Excel
reports into a separate Appium-only artifacts folder.

## Prerequisites

1. Install Node.js `18+`.
2. Install JDK `11` or `17` and configure `JAVA_HOME`.
3. Install Android Studio plus the Android SDK.
4. Ensure `adb` is on your `PATH`.
5. Launch an Android emulator or connect a USB-debuggable Android device.

## Appium And Driver Setup

```bash
npm install -g appium
appium driver install uiautomator2
appium driver list
```

## Preparing The App

Run this from the repo root:

```bash
flutter build apk --debug --dart-define-from-file=env.json
```

The default APK path used by the suite is:
`build/app/outputs/flutter-apk/app-debug.apk`

## Running The Tests

1. Start an emulator or connect a device.
2. Start Appium in a separate terminal:

```bash
appium
```

3. Install the mobile test dependencies:

```bash
npm --prefix appium_tests install
```

4. Run the suite:

```bash
npm run test:appium
npm run test:appium:all
npm run test:appium:mock
```

From inside `appium_tests`:

```bash
npm run test
npm run test:functional
npm run test:ui
npm run test:compatibility
npm run test:e2e
npm run test:all
npm run test:mock
```

Optional environment variables:

- `APPIUM_LIMIT=25` limits each suite to the first 25 cases.
- `APPIUM_MOCK=true` validates the reporting pipeline without a real device.
- `TEST_EMAIL`, `TEST_PASSWORD`, and `ADMIN_EMAIL` enable authenticated flows.

## Reports And Artifacts

- Excel reports are written to [appium_tests/reports](/d:/PDD_final/my_app/appium_tests/reports:1).
- Failure screenshots are written to [appium_tests/reports/evidence](/d:/PDD_final/my_app/appium_tests/reports/evidence:1).
- The mobile markdown summary is written to [appium_tests/TEST_SUMMARY.md](/d:/PDD_final/my_app/appium_tests/TEST_SUMMARY.md:1).

Generate the markdown summary manually with:

```bash
npm run summary:appium
```

## CI Workflow

The Android GitHub Actions pipeline lives in
[mobile-appium-report.yml](/d:/PDD_final/my_app/.github/workflows/mobile-appium-report.yml:1).
It builds the Android APK, boots an emulator, starts Appium, runs the suite,
and uploads the Excel report, screenshots, summary markdown, and Appium server
log as artifacts.
