'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Ace Technologies – Selenium Test Suite  ·  MAIN RUNNER
//  Runs all 11 suites, manages browser lifecycle, and generates Excel report.
//
//  Usage:
//    node runner.js                    # run all suites
//    node runner.js --suite functional # run a specific suite
//    node runner.js --suite e2e        # run only E2E tests
//
//  Environment variables:
//    E2E_BASE_URL      - Base URL of the running app (default: http://127.0.0.1:4173/)
//    HEADLESS          - "false" to show browser window (default: headless)
//    SUPABASE_URL      - Supabase project URL (for API/DB tests)
//    SUPABASE_ANON_KEY - Supabase anon key
//    TEST_EMAIL        - Test user email
//    TEST_PASSWORD     - Test user password
// ─────────────────────────────────────────────────────────────────────────────

const fs   = require('fs');
const http = require('http');
const path = require('path');

const CONFIG    = require('./config/test-config');
const { buildDriver, wait, screenshot } = require('./utils/driver-helpers');
const { generateReport, ensureDirs }    = require('./utils/report-generator');

// ── Suite registry ────────────────────────────────────────────────────────────
const ALL_SUITES = [
  { key: 'functional',     label: 'Functional Testing',      file: './suites/01-functional'     },
  { key: 'ui',             label: 'UI/UX Testing',           file: './suites/02-ui-ux'           },
  { key: 'compatibility',  label: 'Compatibility Testing',   file: './suites/03-compatibility'   },
  { key: 'performance',    label: 'Performance Testing',     file: './suites/04-performance'     },
  { key: 'security',       label: 'Security Testing',        file: './suites/05-security'        },
  { key: 'api',            label: 'API Testing',             file: './suites/06-api'             },
  { key: 'database',       label: 'Database Testing',        file: './suites/07-database'        },
  { key: 'accessibility',  label: 'Accessibility Testing',   file: './suites/08-accessibility'   },
  { key: 'mobile',         label: 'Mobile-Specific Testing', file: './suites/09-mobile'          },
  { key: 'regression',     label: 'Regression Testing',      file: './suites/10-regression'      },
  { key: 'e2e',            label: 'End-to-End (E2E) Testing',file: './suites/11-e2e'             },
];

// ── CLI args ──────────────────────────────────────────────────────────────────
const args       = process.argv.slice(2);
const suiteArg   = args[args.indexOf('--suite') + 1] || 'all';
const selectedSuites = suiteArg === 'all'
  ? ALL_SUITES
  : ALL_SUITES.filter((s) => s.key === suiteArg || s.label.toLowerCase().includes(suiteArg.toLowerCase()));

if (!selectedSuites.length) {
  console.error(`Unknown suite: "${suiteArg}". Valid keys: ${ALL_SUITES.map((s) => s.key).join(', ')}, all`);
  process.exit(1);
}

// ── Static server (for local build) ──────────────────────────────────────────
function startStaticServerIfNeeded() {
  if (process.env.E2E_BASE_URL) return Promise.resolve(null);

  const buildRoot = CONFIG.paths.buildWeb;
  if (!fs.existsSync(path.join(buildRoot, 'index.html'))) {
    console.warn([
      '⚠  No build/web/index.html found.',
      '   Run  flutter build web  to build the app, OR',
      '   set  E2E_BASE_URL=http://your-deployed-url  to test a live server.',
    ].join('\n'));
    return Promise.resolve(null);
  }

  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js':   'application/javascript; charset=utf-8',
    '.css':  'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png':  'image/png',
    '.jpg':  'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg':  'image/svg+xml',
    '.ico':  'image/x-icon',
    '.wasm': 'application/wasm',
    '.woff': 'font/woff',
    '.woff2':'font/woff2',
  };

  const handler = (req, res) => {
    const sanitized = decodeURIComponent((req.url || '/').split('?')[0]).replace(/^\/+/, '');
    const resolved  = path.resolve(buildRoot, sanitized);
    if (!resolved.startsWith(buildRoot)) { res.writeHead(403); res.end('Forbidden'); return; }
    let target = resolved;
    if (fs.existsSync(target) && fs.statSync(target).isDirectory()) target = path.join(target, 'index.html');
    if (!fs.existsSync(target) || !fs.statSync(target).isFile()) target = path.join(buildRoot, 'index.html');
    res.writeHead(200, { 'Content-Type': mimeTypes[path.extname(target).toLowerCase()] || 'application/octet-stream' });
    fs.createReadStream(target).pipe(res);
  };

  // Try ports 4173–4183 to handle parallel suite runs gracefully
  const BASE_PORT = Number(new URL(CONFIG.app.baseUrl).port || 4173);
  const tryPort = (port) => new Promise((resolve, reject) => {
    if (port > BASE_PORT + 10) {
      reject(new Error('No free port found in range 4173-4183'));
      return;
    }
    const server = http.createServer(handler);
    server.once('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.warn(`⚠  Port ${port} in use, trying ${port + 1}…`);
        server.close();
        tryPort(port + 1).then(resolve).catch(reject);
      } else {
        reject(err);
      }
    });
    server.listen(port, '127.0.0.1', () => {
      const url = `http://127.0.0.1:${port}/`;
      CONFIG.app.baseUrl = url; // Update base URL for this process
      console.log(`📦 Static server running at ${url}`);
      resolve(server);
    });
  });

  return tryPort(BASE_PORT);
}

// ── Suite-level driver management ─────────────────────────────────────────────
//  Only 'api' suite runs entirely without a browser.
//  'database' uses openRoute/assertReadablePage and needs a driver.
const NO_DRIVER_SUITES = new Set(['api']);

// ── Test runner ───────────────────────────────────────────────────────────────
async function runSuite(suiteModule, suiteKey) {
  const cases   = suiteModule.makeCases();
  const results = [];
  const needsDriver = !NO_DRIVER_SUITES.has(suiteKey);

  let driver = null;
  if (needsDriver) {
    driver = await buildDriver();
  }

  /** Rebuild the driver when Chrome crashes (e.g. after many viewport changes). */
  async function recoverDriver() {
    try { await driver.quit(); } catch (_) {}
    driver = await buildDriver();
    console.log('  🔄 Driver restarted after session failure');
  }

  for (const testCase of cases) {
    const started = Date.now();
    try {
      await testCase.run(driver);
      results.push({
        ...testCase,
        status:     'PASS',
        actual:     'Passed',
        durationMs: Date.now() - started,
        timestamp:  new Date().toISOString(),
        evidence:   '',
      });
      console.log(`  ✅ PASS  ${testCase.id}  ${testCase.title}`);
    } catch (err) {
      const message = err && err.message ? err.message : String(err);
      const isSessionDead = message.includes('invalid session id') ||
                            message.includes('session deleted') ||
                            message.includes('no such session') ||
                            message.includes('chrome not reachable');

      // Auto-recover and retry once if Chrome session crashed
      if (isSessionDead && needsDriver) {
        console.log(`  ⚠  Session crashed on ${testCase.id} — recovering driver…`);
        await recoverDriver();
        // Retry the test once with fresh driver
        const retryStart = Date.now();
        try {
          await testCase.run(driver);
          results.push({
            ...testCase,
            status:     'PASS',
            actual:     'Passed (after driver recovery)',
            durationMs: Date.now() - retryStart,
            timestamp:  new Date().toISOString(),
            evidence:   '',
          });
          console.log(`  ✅ PASS  ${testCase.id}  ${testCase.title}  (retry)`);
          continue;
        } catch (retryErr) {
          // Fall through to record as FAIL
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
        status:     'FAIL',
        actual:     finalMessage,
        durationMs: Date.now() - started,
        timestamp:  new Date().toISOString(),
        evidence:   evidencePath,
      });
      console.log(`  ❌ FAIL  ${testCase.id}  ${testCase.title}\n        → ${finalMessage.slice(0, 120)}`);
    }
  }

  if (driver) {
    await driver.quit().catch(() => {});
  }

  return { cases, results };
}

// ── Main orchestrator ─────────────────────────────────────────────────────────
async function main() {
  ensureDirs();
  const startedAt = new Date();

  console.log('\n' + '═'.repeat(70));
  console.log(' 🧪  ACE TECHNOLOGIES – SELENIUM TEST SUITE');
  console.log(`     App : ${CONFIG.app.baseUrl}`);
  console.log(`     Mode: ${CONFIG.browser.headless ? 'Headless' : 'Headed'}`);
  console.log(`     Suite(s): ${selectedSuites.map((s) => s.label).join(', ')}`);
  console.log('═'.repeat(70) + '\n');

  // Start static server if needed
  const server = await startStaticServerIfNeeded().catch((err) => {
    console.warn(`⚠  Could not start static server: ${err.message}`);
    return null;
  });

  const allCases   = [];
  const allResults = [];
  let totalPassed  = 0;
  let totalFailed  = 0;

  for (const suite of selectedSuites) {
    console.log(`\n${'─'.repeat(60)}`);
    console.log(`▶  ${suite.label}`);
    console.log(`${'─'.repeat(60)}`);

    let suiteModule;
    try {
      suiteModule = require(suite.file);
    } catch (err) {
      console.error(`  ⚠ Could not load suite "${suite.file}": ${err.message}`);
      continue;
    }

    const { cases, results } = await runSuite(suiteModule, suite.key).catch((err) => {
      console.error(`  ❌ Suite "${suite.label}" crashed: ${err.message}`);
      return { cases: [], results: [] };
    });

    allCases.push(...cases);
    allResults.push(...results);

    const passed = results.filter((r) => r.status === 'PASS').length;
    const failed = results.filter((r) => r.status === 'FAIL').length;
    totalPassed += passed;
    totalFailed += failed;

    console.log(`\n  Summary: ${passed} passed, ${failed} failed of ${results.length} tests`);

    // Write incremental report every suite
    if (allResults.length > 0) {
      generateReport(allResults, allCases, startedAt);
    }
  }

  // ── Final summary ─────────────────────────────────────────────────────────
  const reportPath = allResults.length > 0
    ? generateReport(allResults, allCases, startedAt)
    : null;

  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }

  console.log('\n' + '═'.repeat(70));
  console.log(` 📊  FINAL RESULTS`);
  console.log(`     Total Cases  : ${allCases.length}`);
  console.log(`     Executed     : ${allResults.length}`);
  console.log(`     ✅ Passed    : ${totalPassed}`);
  console.log(`     ❌ Failed    : ${totalFailed}`);
  console.log(`     Pass Rate    : ${allResults.length ? Math.round(totalPassed / allResults.length * 100) : 0}%`);
  if (reportPath) console.log(`     📁 Report    : ${reportPath}`);
  console.log('═'.repeat(70) + '\n');

  if (totalFailed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error('\n💥 Runner crashed:', err);
  process.exit(1);
});
