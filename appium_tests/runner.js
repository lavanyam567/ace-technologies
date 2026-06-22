'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Ace Technologies – Appium Test Suite  ·  MAIN RUNNER
//  Runs mobile test suites, manages driver sessions, and outputs Excel reports.
//
//  Usage:
//    node runner.js                     # run default E2E suite
//    node runner.js --suite functional  # run functional tests
//    node runner.js --suite all         # run all suites
//
//  Environment variables:
//    APPIUM_MOCK      - Set "true" to run in mock simulation mode (no Appium server needed)
//    APPIUM_LIMIT     - Optional max number of test cases to execute per suite
//    APP_APK_PATH     - Path to the android debug APK
//    ANDROID_DEVICE_NAME - Target emulator name (default: "Android Emulator")
//    TEST_EMAIL       - Valid credentials for testing
//    TEST_PASSWORD    - Valid credentials password
// ─────────────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');

const CONFIG = require('./config/test-config');
const { buildDriver, wait, screenshot, isMockDriver, openRoute, clickText, pageText } = require('./utils/driver-helpers');
const { generateReport, ensureDirs } = require('./utils/report-generator');

// ── Suite registry ────────────────────────────────────────────────────────────
const ALL_SUITES = [
  { key: 'functional',    label: 'Functional Testing',      file: './suites/01-functional' },
  { key: 'ui',            label: 'UI/UX Testing',           file: './suites/02-ui-ux' },
  { key: 'compatibility', label: 'Compatibility Testing',   file: './suites/03-compatibility' },
  { key: 'e2e',           label: 'End-to-End (E2E) Testing',file: './suites/11-e2e' },
];

// ── CLI args ──────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const suiteArg = args[args.indexOf('--suite') + 1] || 'e2e'; // Default to e2e
const selectedSuites = suiteArg === 'all'
  ? ALL_SUITES
  : ALL_SUITES.filter((s) => s.key === suiteArg || s.label.toLowerCase().includes(suiteArg.toLowerCase()));

if (!selectedSuites.length) {
  console.error(`Unknown suite: "${suiteArg}". Valid keys: ${ALL_SUITES.map((s) => s.key).join(', ')}, all`);
  process.exit(1);
}

// ── Test runner ───────────────────────────────────────────────────────────────
async function runSuite(suiteModule, suiteKey) {
  const allCases = suiteModule.makeCases();
  const limit = Number(process.env.APPIUM_LIMIT || '0');
  const cases = limit > 0 ? allCases.slice(0, limit) : allCases;
  const results = [];

  let driver = await buildDriver();
  const isMock = isMockDriver(driver);

  async function recoverDriver() {
    if (isMock) return;
    try { await driver.deleteSession(); } catch (_) {}
    driver = await buildDriver();
    console.log('  🔄 Driver session restarted after failure');
  }

  // Ensure we start in a guest state (log out if we are logged in)
  if (!isMock) {
    try {
      console.log('  🧹 Checking authentication state (ensuring guest mode)...');
      await openRoute(driver, '/account');
      const text = await pageText(driver);
      if (text.includes('Logout') || text.includes('Sign Out')) {
        console.log('  🧹 Logged-in session detected. Logging out...');
        await clickText(driver, 'Logout');
        await wait(1500);
      } else {
        console.log('  🧹 Confirmed guest mode.');
      }
      // Reset view to Home screen
      await openRoute(driver, '/');
    } catch (err) {
      console.warn('  ⚠️ Warning: Failed to ensure guest state:', err.message);
    }
  }

  for (const testCase of cases) {
    const started = Date.now();
    try {
      await testCase.run(driver);
      results.push({
        ...testCase,
        status: 'PASS',
        actual: 'Passed',
        durationMs: Date.now() - started,
        timestamp: new Date().toISOString(),
        evidence: '',
      });
      console.log(`  ✅ PASS  ${testCase.id}  ${testCase.title}`);
    } catch (err) {
      const message = err && err.message ? err.message : String(err);
      const isSessionDead = message.includes('session') ||
                            message.includes('disconnected') ||
                            message.includes('shutting down') ||
                            message.includes('not reachable');

      // Auto-recover and retry once if session crashed
      if (isSessionDead && !isMock) {
        console.log(`  ⚠️  Session crashed on ${testCase.id} — recovering driver…`);
        await recoverDriver();
        
        const retryStart = Date.now();
        try {
          await testCase.run(driver);
          results.push({
            ...testCase,
            status: 'PASS',
            actual: 'Passed (after driver recovery)',
            durationMs: Date.now() - retryStart,
            timestamp: new Date().toISOString(),
            evidence: '',
          });
          console.log(`  ✅ PASS  ${testCase.id}  ${testCase.title}  (retry)`);
          continue;
        } catch (retryErr) {
          err = retryErr;
        }
      }

      let evidencePath = '';
      if (driver && !isSessionDead) {
        evidencePath = await screenshot(driver, `${testCase.id}-failure`).catch(() => '');
      }
      const finalMessage = err && err.message ? err.message : String(err);
      results.push({
        ...testCase,
        status: 'FAIL',
        actual: finalMessage,
        durationMs: Date.now() - started,
        timestamp: new Date().toISOString(),
        evidence: evidencePath,
      });
      console.log(`  ❌ FAIL  ${testCase.id}  ${testCase.title}\n        → ${finalMessage.slice(0, 120)}`);
    }
  }

  if (driver) {
    try {
      await driver.deleteSession();
    } catch (_) {}
  }

  return { cases, results, isMock };
}

// ── Main orchestrator ─────────────────────────────────────────────────────────
async function main() {
  ensureDirs();
  const startedAt = new Date();

  console.log('\n' + '═'.repeat(70));
  console.log(' 🧪  ACE TECHNOLOGIES – APPIUM ANDROID TEST SUITE');
  console.log(`     APK : ${CONFIG.app.apkPath}`);
  console.log(`     Device: ${CONFIG.capabilities['appium:deviceName']} (Android ${CONFIG.capabilities['appium:platformVersion']})`);
  console.log(`     Suite(s): ${selectedSuites.map((s) => s.label).join(', ')}`);
  if (Number(process.env.APPIUM_LIMIT || '0') > 0) {
    console.log(`     Case limit: ${process.env.APPIUM_LIMIT} per suite`);
  }
  console.log('═'.repeat(70) + '\n');

  const allCases = [];
  const allResults = [];
  let totalPassed = 0;
  let totalFailed = 0;
  let runningWithMock = false;

  for (const suite of selectedSuites) {
    console.log(`\n${'─'.repeat(60)}`);
    console.log(`▶  ${suite.label}`);
    console.log(`${'─'.repeat(60)}`);

    let suiteModule;
    try {
      suiteModule = require(suite.file);
    } catch (err) {
      console.error(`  ⚠️ Could not load suite "${suite.file}": ${err.message}`);
      continue;
    }

    const { cases, results, isMock } = await runSuite(suiteModule, suite.key).catch((err) => {
      console.error(`  ❌ Suite "${suite.label}" crashed: ${err.message}`);
      return { cases: [], results: [], isMock: false };
    });

    if (isMock) {
      runningWithMock = true;
    }

    allCases.push(...cases);
    allResults.push(...results);

    const passed = results.filter((r) => r.status === 'PASS').length;
    const failed = results.filter((r) => r.status === 'FAIL').length;
    totalPassed += passed;
    totalFailed += failed;

    console.log(`\n  Summary: ${passed} passed, ${failed} failed of ${results.length} tests`);

    // Write incremental report
    if (allResults.length > 0) {
      generateReport(allResults, allCases, startedAt, runningWithMock);
    }
  }

  // Final report write
  const reportPath = allResults.length > 0
    ? generateReport(allResults, allCases, startedAt, runningWithMock)
    : null;

  console.log('\n' + '═'.repeat(70));
  console.log(` 📊  FINAL RESULTS`);
  console.log(`     Total Cases  : ${allCases.length}`);
  console.log(`     Executed     : ${allResults.length}`);
  console.log(`     ✅ Passed    : ${totalPassed}`);
  console.log(`     ❌ Failed    : ${totalFailed}`);
  console.log(`     Pass Rate    : ${allResults.length ? Math.round(totalPassed / allResults.length * 100) : 0}%`);
  
  if (reportPath) {
    console.log(`     📁 Report    : ${reportPath}`);
    try {
      const { execSync } = require('child_process');
      console.log('     📝 Generating Markdown summary...');
      execSync(`node "${path.resolve(__dirname, '../scripts/generate-markdown-summary.js')}"`, {
        stdio: 'inherit',
        env: {
          ...process.env,
          REPORTS_DIR: CONFIG.paths.reports,
          SUMMARY_OUTPUT: CONFIG.paths.summary,
        },
      });
    } catch (err) {
      console.error('     ❌ Failed to generate Markdown summary:', err.message);
    }
  }
  console.log('═'.repeat(70) + '\n');

  if (totalFailed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error('\n💥 Runner crashed:', err);
  process.exit(1);
});
