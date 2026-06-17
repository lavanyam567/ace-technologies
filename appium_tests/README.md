# Ace Technologies – Appium Android Testing Suite

This folder contains the automated end-to-end (E2E) and functional testing suite for the Android mobile application version of **Ace Technologies**, using **Appium** and **WebdriverIO**.

---

## 📋 Prerequisites

To run these tests, you must set up the mobile testing environment on your machine:

1. **Node.js**: Ensure Node.js (version 18 or higher) is installed.
2. **Java Development Kit (JDK)**: Install JDK 11 or 17. Configure the `JAVA_HOME` environment variable.
3. **Android SDK**: Install Android Studio and configure the Android SDK.
   - Ensure the `ANDROID_HOME` environment variable is set to your Android SDK path (e.g. `C:\Users\<username>\AppData\Local\Android\Sdk`).
   - Add platform-tools (containing `adb`) to your system Path.
4. **Android Emulator / Device**: Set up a virtual device (AVD) using Android Studio and launch it. Alternatively, connect a physical Android device with USB debugging enabled.

---

## 🛠️ Appium & Driver Setup

1. **Install Appium Server Globally** (requires Node.js):
   ```bash
   npm install -g appium
   ```
2. **Install the UiAutomator2 Driver**:
   ```bash
   appium driver install uiautomator2
   ```
3. **Verify Appium Installation**:
   Ensure Appium and driver are successfully installed:
   ```bash
   appium driver list
   ```

---

## 📦 Preparing the App

Before running the tests, build the Android application package (APK) of the Flutter app in debug mode:

```bash
# Run from the root of "my_app" folder
flutter build apk --debug
```

This compiles and saves the APK at the default location:
`my_app/build/app/outputs/flutter-apk/app-debug.apk`

---

## 🚀 Running the Tests

1. **Start your Android Emulator** or connect a physical device via USB (make sure it shows up when running `adb devices`).
2. **Start the Appium Server**:
   ```bash
   appium
   ```
   *(Keep this terminal open; it will listen on `http://127.0.0.1:4723/` by default).*
3. **Install Client Dependencies**:
   Open a separate terminal, navigate to the `appium_tests` folder, and run:
   ```bash
   npm install
   ```
4. **Execute Tests**:
   - **From root `my_app` directory**:
     ```bash
     npm run test:appium       # Runs the default suite (E2E)
     npm run test:appium:all   # Runs all suites
     ```
   - **From `appium_tests` directory**:
     ```bash
     npm run test              # Runs the E2E suite
     npm run test:functional   # Runs only functional tests
     npm run test:ui           # Runs only UI/UX tests
     npm run test:e2e          # Runs E2E tests
     npm run test:all          # Runs all suites
     ```

---

## 📊 Reports & Artifacts

After completion:
1. **Excel Report**: A styled Excel spreadsheet named `Ace_Technologies_Appium_TestReport_<timestamp>.xlsx` is generated in `my_app/reports/`.
2. **Screenshots on Failure**: Visual evidence for any failed test cases is saved in `my_app/reports/evidence/`.
3. **Markdown Summary**: You can update the root `TEST_SUMMARY.md` file by running:
   ```bash
   npm run summary
   ```

---

## 📂 Configuration

Device specifications, Appium ports, and test credentials can be customized in [config/test-config.js](file:///d:/PDD_final/my_app/appium_tests/config/test-config.js).
By default, the capabilities are set to:
* **Platform**: Android
* **Automation**: UiAutomator2
* **Device Name**: Android Emulator
* **App Path**: `../build/app/outputs/flutter-apk/app-debug.apk`
