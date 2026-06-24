'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Ace Technologies – Appium Android Test Suite  ·  Central Configuration
// ─────────────────────────────────────────────────────────────────────────────

const path = require('path');
const { execSync } = require('child_process');

const APPIUM_HOST = process.env.APPIUM_HOST || '127.0.0.1';
const APPIUM_PORT = Number(process.env.APPIUM_PORT || '4723');
const APPIUM_PATH = process.env.APPIUM_PATH || '/';
const TIMEOUT_MS  = Number(process.env.E2E_TIMEOUT_MS || 15000);
const SLOW_MS     = Number(process.env.E2E_SLOW_MS    || 500);

// Default to the typical Flutter Android build output path
const DEFAULT_APK_PATH = path.resolve(__dirname, '../../build/app/outputs/flutter-apk/app-debug.apk');
const APK_PATH = process.env.APP_APK_PATH || DEFAULT_APK_PATH;

// Detect device name and platform version dynamically
let detectedDevice = 'RZCW40TQTAA';
let detectedVersion = '15';

try {
  const devicesOutput = execSync('adb devices', { stdio: ['ignore', 'pipe', 'ignore'] }).toString();
  const lines = devicesOutput.split('\n')
    .map(line => line.trim())
    .filter(line => line && !line.startsWith('List of devices'));
  if (lines.length > 0) {
    const firstDevice = lines[0].split(/\s+/)[0];
    if (firstDevice) {
      detectedDevice = firstDevice;
      const versionOutput = execSync(
        `adb -s ${detectedDevice} shell getprop ro.build.version.release`,
        { stdio: ['ignore', 'pipe', 'ignore'] }
      ).toString().trim();
      if (versionOutput) {
        detectedVersion = versionOutput;
      }
    }
  }
} catch (e) {
  // Silent fallback
}

const DEVICE_NAME = process.env.ANDROID_DEVICE_NAME || detectedDevice;
const PLATFORM_VERSION = process.env.ANDROID_PLATFORM_VERSION || detectedVersion;

const CONFIG = {
  // ── Application ──────────────────────────────────────────────────────────
  app: {
    name: 'Ace Technologies',
    package: 'com.acetechnologies.app',
    mainActivity: 'com.acetechnologies.app.MainActivity',
    apkPath: APK_PATH,
  },

  // ── Appium Server Configuration ──────────────────────────────────────────
  appium: {
    host: APPIUM_HOST,
    port: APPIUM_PORT,
    path: APPIUM_PATH,
    protocol: 'http',
  },

  // ── Device Capabilities ──────────────────────────────────────────────────
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': DEVICE_NAME,
    'appium:platformVersion': PLATFORM_VERSION,
    'appium:app': APK_PATH,
    'appium:appPackage': 'com.acetechnologies.app',
    'appium:appActivity': 'com.acetechnologies.app.MainActivity',
    'appium:noReset': false,
    'appium:fullReset': false,
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 300,
  },

  // ── Timeouts ──────────────────────────────────────────────────────────────
  timeouts: {
    assertion: TIMEOUT_MS,
    navigation: 12000,
    animation: 800,
    slow: SLOW_MS,
    flutterBoot: 8000, // Flutter apps take a bit longer to initialize graphics engine
  },

  // ── Paths ─────────────────────────────────────────────────────────────────
  paths: {
    root: path.resolve(__dirname, '..'),
    reports: path.resolve(__dirname, '../reports'),
    evidence: path.resolve(__dirname, '../reports/evidence'),
    summary: path.resolve(__dirname, '../TEST_SUMMARY.md'),
  },

  // ── Test Credentials (non-production) ────────────────────────────────────
  credentials: {
    validEmail: process.env.TEST_EMAIL || 'test@acetechnologies.com',
    validPassword: process.env.TEST_PASSWORD || 'Test@123456',
    invalidEmail: 'notanemail',
    invalidPassword: 'wrong',
    adminEmail: process.env.ADMIN_EMAIL || 'admin@acetechnologies.com',
  },

  // ── Mobile Screen Names (analogous to routes) ────────────────────────────
  screens: {
    home: 'Home Screen',
    products: 'Products Screen',
    services: 'Services Screen',
    about: 'About Us Screen',
    cart: 'Cart Screen',
    account: 'Account Screen',
    login: 'Login Screen',
    signup: 'Signup Screen',
    orders: 'Orders Screen',
    checkout: 'Checkout Screen',
    wishlist: 'Wishlist Screen',
    recent: 'Recent Screen',
  }
};

module.exports = CONFIG;
