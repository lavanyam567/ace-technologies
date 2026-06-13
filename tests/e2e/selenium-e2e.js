const fs = require('fs');
const path = require('path');
const http = require('http');
const XLSX = require('xlsx');
const { Builder, By, Key } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

const DEFAULT_PORT = Number.parseInt(process.env.E2E_SERVER_PORT || '4173', 10);
const BUILD_ROOT = path.resolve(__dirname, '../../build/web');
const BASE_URL = process.env.E2E_BASE_URL || `http://127.0.0.1:${DEFAULT_PORT}/`;
const HEADLESS = process.env.HEADLESS !== 'false';
const LIMIT = Number.parseInt(process.env.E2E_LIMIT || '0', 10);
const CASE_IDS = new Set(
  String(process.env.E2E_CASE_IDS || '')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean),
);
const ASSERT_TIMEOUT_MS = Number.parseInt(process.env.E2E_ASSERT_TIMEOUT_MS || '9000', 10);
const REPORT_DIR = path.resolve(__dirname, '../../reports');
const EVIDENCE_DIR = path.join(REPORT_DIR, 'evidence');
const STARTED_AT = new Date();
const REPORT_PATH = path.join(
  REPORT_DIR,
  `E2E_Test_Report_AceTechnologies_${STARTED_AT.toISOString().replace(/[:.]/g, '-')}.xlsx`,
);

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const pageUrl = (route) => new URL(route, BASE_URL).toString();

function ensureReportDirs() {
  fs.mkdirSync(REPORT_DIR, { recursive: true });
  fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
}

function normalizeText(text) {
  return String(text || '').replace(/\s+/g, ' ').trim().toLowerCase();
}

function slugify(text) {
  return String(text).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 80);
}

async function pageText(driver) {
  return driver.executeScript(`
    if (!document.body) return "";
    const values = [document.body.innerText || ""];
    for (const el of document.body.querySelectorAll('[aria-label], [placeholder], [title], [alt], input, textarea, button')) {
      values.push(
        el.getAttribute('aria-label') || '',
        el.getAttribute('placeholder') || '',
        el.getAttribute('title') || '',
        el.getAttribute('alt') || '',
        el.value || '',
        el.textContent || ''
      );
    }
    return values.filter(Boolean).join("\\n");
  `);
}

async function scrollViewport(driver, deltaY = 600) {
  const key = deltaY >= 0 ? Key.PAGE_DOWN : Key.PAGE_UP;
  await driver.findElement(By.css('body')).sendKeys(key).catch(() => {});
  const rect = await driver.manage().window().getRect();
  await driver.actions({ async: true })
    .scroll(Math.floor(rect.width * 0.7), Math.floor(rect.height * 0.5), 0, deltaY)
    .perform()
    .catch(() => {});
  await wait(150);
}

async function waitForAppReady(driver) {
  await driver.wait(async () => {
    const readyState = await driver.executeScript('return document.readyState');
    return readyState === 'interactive' || readyState === 'complete';
  }, ASSERT_TIMEOUT_MS).catch(() => {});
  await wait(900);
}

async function openRoute(driver, route) {
  await driver.get(pageUrl(route));
  await waitForAppReady(driver);
}

async function assertReadablePage(driver) {
  await driver.wait(async () => normalizeText(await pageText(driver)).length > 10, ASSERT_TIMEOUT_MS, 'Expected readable page text');
}

async function assertAnyText(driver, expected) {
  const expectedList = Array.isArray(expected) ? expected : [expected];
  const needles = expectedList.map(normalizeText);
  let scrolls = 0;
  const initialDeadline = Date.now() + 1800;
  await driver.wait(async () => {
    const body = normalizeText(await pageText(driver));
    if (needles.some((needle) => body.includes(needle))) return true;
    if (Date.now() < initialDeadline) {
      await wait(150);
      return false;
    }
    if (scrolls < 14) {
      scrolls += 1;
      await scrollViewport(driver);
    }
    return false;
  }, ASSERT_TIMEOUT_MS, `Expected any visible text: ${expectedList.join(' | ')}`);
}

async function assertAllText(driver, expectedList) {
  for (const expected of expectedList) await assertAnyText(driver, expected);
}

async function setFirstInput(driver, value) {
  const inputs = await driver.findElements(By.css('input, textarea'));
  if (!inputs.length) throw new Error('No text input found');
  await inputs[0].sendKeys(Key.chord(Key.CONTROL, 'a'), Key.DELETE, value);
}

async function clickText(driver, text) {
  const desktopNavY = {
    Home: 104,
    Products: 153,
    Services: 202,
    About: 251,
    'About Us': 251,
    Cart: 300,
    Account: 349,
  };
  if (desktopNavY[text]) {
    const rect = await driver.manage().window().getRect();
    if (rect.width >= 900) {
      await driver.actions({ async: true })
        .move({ x: 90, y: desktopNavY[text] })
        .click()
        .perform();
      await wait(300);
      return;
    }
  }

  const lower = normalizeText(text).replace(/'/g, "\\'");
  const xpath = `//*[@role='button' or self::button or self::a][contains(translate(normalize-space(.), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '${lower}') or contains(translate(@aria-label, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '${lower}')]`;
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const elements = await driver.findElements(By.xpath(xpath));
    for (const element of elements) {
      try {
        await driver.executeScript('arguments[0].scrollIntoView({block:"center", inline:"center"});', element);
        await wait(120);
        if (await element.isDisplayed()) {
          await element.click().catch(() => driver.executeScript('arguments[0].click();', element));
          await wait(300);
          return;
        }
      } catch (_) {}
    }
    const semanticTarget = await driver.findElements(By.css(`[aria-label="${text.replace(/"/g, '\\"')}"]`));
    if (semanticTarget.length) {
      const clicked = await driver.executeScript(`
        const target = arguments[0];
        target.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
        return true;
      `, semanticTarget[0]).catch(() => false);
      if (clicked) {
        await wait(300);
        return;
      }
    }
    await scrollViewport(driver);
  }
  throw new Error(`No visible clickable text: ${text}`);
}

async function screenshotOnFailure(driver, testCaseId) {
  ensureReportDirs();
  const filepath = path.join(EVIDENCE_DIR, `${testCaseId}-${Date.now()}.png`);
  try {
    const image = await driver.takeScreenshot();
    fs.writeFileSync(filepath, image, 'base64');
    return filepath;
  } catch (_) {
    return '';
  }
}

function addCase(cases, id, title, area, route, expected, run, priority = 'Medium') {
  cases.push({ id, title, area, route, expected, priority, run });
}

function makeCases() {
  const cases = [];
  let n = 1;
  const nextId = () => `E2E-${String(n++).padStart(3, '0')}`;

  const coreRoutes = [
    ['/', 'Home', ['Ace Technologies', 'Home Screen']],
    ['/products', 'Products', ['Products', 'Products Screen']],
    ['/services', 'Services', ['Services', 'Services Screen']],
    ['/about', 'About', ['About Us', 'Our Objective']],
    ['/cart', 'Cart', ['Shopping Cart', 'cart']],
    ['/account', 'Account', ['Account', 'Login to your account']],
    ['/notifications', 'Notifications', ['Notifications']],
    ['/deals', 'Featured Deals', ['Featured Deals', 'Deals']],
    ['/wishlist', 'Wishlist', ['Wishlist']],
    ['/compare', 'Compare Products', ['Compare Products', 'Compare']],
    ['/recent', 'Recently Viewed', ['Recently Viewed', 'Recent']],
    ['/checkout', 'Checkout', ['Checkout']],
    ['/checkout/address', 'Address Selection', ['Address', 'Select Address']],
    ['/checkout/address/new', 'Add Address', ['Address']],
    ['/checkout/payment', 'Payment Method', ['Payment']],
    ['/orders', 'My Orders', ['Orders', 'My Orders']],
    ['/service-history', 'Service History', ['Bookings', 'Service']],
    ['/login', 'Login', ['Sign In']],
    ['/signup', 'Signup', ['Sign Up', 'Create Account']],
    ['/profile', 'Profile', ['Profile', 'Account']],
    ['/settings', 'Settings', ['Settings']],
    ['/admin/orders', 'Admin Orders', ['Admin', 'Orders']],
    ['/search?q=laptop', 'Search Results', ['Search', 'laptop', 'Products']],
    ['/products/filter', 'Product Filters', ['Filter', 'Sort']],
    ['/product/sample-product', 'Product Detail', ['Product', 'sample']],
    ['/product/sample-product/gallery', 'Product Gallery', ['Gallery', 'Product']],
    ['/product/sample-product/reviews', 'Product Reviews', ['Reviews', 'Product']],
    ['/product/sample-product/write-review', 'Write Review', ['Review', 'Product']],
    ['/service/sample-service', 'Service Detail', ['Service', 'sample']],
    ['/service/sample-service/book', 'Book Service', ['Book', 'Service']],
    ['/service/sample-service/schedule', 'Schedule Service', ['Schedule', 'Service']],
    ['/service/sample-service/confirmation?bookingId=test-booking', 'Service Confirmation', ['Confirmation', 'Booking', 'Service']],
    ['/order/test-order', 'Order Detail', ['Order']],
    ['/order/test-order/track', 'Track Order', ['Track', 'Order']],
    ['/order-success/test-order', 'Order Success', ['Order', 'Success']],
  ];

  for (const [route, name, expected] of coreRoutes) {
    addCase(cases, nextId(), `${name} route renders`, 'Routing', route, expected.join(' | '), async (driver) => {
      await openRoute(driver, route);
      await assertReadablePage(driver);
      await assertAnyText(driver, expected);
    }, 'High');
  }

  for (const [route, name] of coreRoutes.slice(0, 24)) {
    addCase(cases, nextId(), `${name} route survives browser refresh`, 'Stability', route, 'Readable page after refresh', async (driver) => {
      await openRoute(driver, route);
      await driver.navigate().refresh();
      await waitForAppReady(driver);
      await assertReadablePage(driver);
    }, 'High');
  }

  for (const [label, route, expected] of [
    ['Products', '/', ['Products', 'Products Screen']],
    ['Services', '/', ['Services', 'Services Screen']],
    ['About', '/', ['About Us', 'Our Objective']],
    ['Cart', '/', ['Shopping Cart', 'cart']],
    ['Account', '/', ['Account', 'Login to your account']],
  ]) {
    addCase(cases, nextId(), `Main navigation opens ${label}`, 'Navigation', route, label, async (driver) => {
      await openRoute(driver, route);
      await clickText(driver, label);
      await assertAnyText(driver, expected);
    }, 'High');
  }

  for (const text of [
    'Ace Technologies',
    'One-Stop Solution',
    'Products',
    'Services',
    'About',
    'Cart',
    'Account',
  ]) {
    addCase(cases, nextId(), `Home exposes ${text}`, 'Home', '/', text, async (driver) => {
      await openRoute(driver, '/');
      if (text === 'About') {
        await clickText(driver, 'About');
        await assertAnyText(driver, 'About Us');
      } else if (text === 'Cart') {
        await clickText(driver, 'Cart');
        await assertAnyText(driver, ['Shopping Cart', 'Your cart is empty']);
      } else {
        await assertAnyText(driver, text);
      }
    });
  }

  for (const text of [
    'Ace Technologies',
    'One-stop IT',
    'IT & Security',
    'Networking',
    'Service Team',
    'Our Objective',
    'Our Philosophy',
    'Capabilities',
    'Services',
    'Authorized For',
    'Our Resources',
    'Clients',
    'Contact Us',
    'Muralidharan P',
    '9444048910',
    'Chennai',
    'HP Compaq',
    'Samsung',
    'Dahua',
    'Hikvision',
    'Server, laptop installation',
    'Firewall and security solutions',
    'Door access configuration',
  ]) {
    addCase(cases, nextId(), `About page exposes ${text}`, 'About', '/about', text, async (driver) => {
      await openRoute(driver, '/about');
      await assertAnyText(driver, text);
    });
  }

  for (const text of [
    'Login to your account',
    'View orders, wishlist, addresses, and settings.',
    'Email',
    'Password',
    'Login',
    'Create account',
  ]) {
    addCase(cases, nextId(), `Account guest form exposes ${text}`, 'Account', '/account', text, async (driver) => {
      await openRoute(driver, '/account');
      await assertAnyText(driver, text);
    });
  }

  addCase(cases, nextId(), 'Account empty login validation appears', 'Account', '/account', 'Enter email and password', async (driver) => {
    await openRoute(driver, '/account');
    await clickText(driver, 'Login');
    await assertAnyText(driver, 'Enter email and password');
  }, 'High');

  addCase(cases, nextId(), 'Account create account link navigates to signup', 'Account', '/account', 'Signup screen', async (driver) => {
    await openRoute(driver, '/account');
    await clickText(driver, 'Create account');
    await assertAnyText(driver, ['Sign Up', 'Create Account', 'Signup']);
  }, 'High');

  for (const query of [
    '/?code=fake-oauth-code',
    '/?error=access_denied',
    '/search?q=router',
    '/search?q=firewall',
    '/search?q=cctv',
    '/products?category=Laptops',
    '/products?category=Networking',
    '/products?category=Printers',
    '/products?search=keyboard',
    '/products?search=monitor',
    '/products?search=ram',
    '/products?search=camera',
  ]) {
    addCase(cases, nextId(), `URL state renders ${query}`, 'URL State', query, 'Readable state route', async (driver) => {
      await openRoute(driver, query);
      await assertReadablePage(driver);
    });
  }

  for (const [width, height] of [[390, 844], [768, 1024], [1366, 768], [1600, 900]]) {
    for (const [route, expected] of [
      ['/', ['Ace Technologies', 'Home Screen']],
      ['/products', ['Products', 'Products Screen']],
      ['/services', ['Services', 'Services Screen']],
      ['/about', ['About Us', 'Our Objective']],
      ['/account', ['Account', 'Login to your account']],
    ]) {
      addCase(cases, nextId(), `Responsive ${route} at ${width}x${height}`, 'Responsive', route, `${width}x${height}`, async (driver) => {
        await driver.manage().window().setRect({ width, height });
        await openRoute(driver, route);
        await assertAnyText(driver, expected);
      });
    }
  }

  for (const route of ['/', '/products', '/services', '/about', '/account']) {
    addCase(cases, nextId(), `Text input smoke on ${route}`, 'Interaction', route, 'Input interaction does not crash', async (driver) => {
      await openRoute(driver, route);
      try {
        await setFirstInput(driver, 'selenium-smoke@example.com');
      } catch (_) {}
      await assertReadablePage(driver);
    });
  }

  const selected = CASE_IDS.size > 0 ? cases.filter((testCase) => CASE_IDS.has(testCase.id)) : cases;
  return LIMIT > 0 ? selected.slice(0, LIMIT) : selected;
}

function writeReport(results, cases) {
  ensureReportDirs();
  const passed = results.filter((r) => r.status === 'PASS').length;
  const failed = results.filter((r) => r.status === 'FAIL').length;
  const notRun = cases.length - results.length;
  const summary = [
    ['Application', 'Ace Technologies'],
    ['Base URL', BASE_URL],
    ['Started At', STARTED_AT.toISOString()],
    ['Report Generated At', new Date().toISOString()],
    ['Total Planned Cases', cases.length],
    ['Executed Cases', results.length],
    ['Passed', passed],
    ['Failed', failed],
    ['Not Run', notRun],
    ['Headless', HEADLESS ? 'Yes' : 'No'],
  ];

  const detailRows = results.map((r) => ({
    'Test Case ID': r.id,
    Module: r.area,
    Priority: r.priority,
    Route: r.route,
    'Test Scenario': r.title,
    'Expected Result': r.expected,
    Status: r.status,
    'Actual Result': r.actual,
    'Duration (ms)': r.durationMs,
    Evidence: r.evidence || '',
    Timestamp: r.timestamp,
  }));

  const coverageRows = cases.map((c) => {
    const result = results.find((r) => r.id === c.id);
    return {
      'Test Case ID': c.id,
      Module: c.area,
      Priority: c.priority,
      Route: c.route,
      'Test Scenario': c.title,
      Status: result ? result.status : 'NOT RUN',
    };
  });

  const failureRows = results
    .filter((r) => r.status === 'FAIL')
    .map((r) => ({
      'Test Case ID': r.id,
      Module: r.area,
      Route: r.route,
      'Failure Detail': r.actual,
      Evidence: r.evidence || '',
    }));

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(summary), 'Summary');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(detailRows), 'E2E Test Cases');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(coverageRows), 'Coverage Matrix');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(failureRows), 'Failures');

  const tempPath = REPORT_PATH.replace(/\.xlsx$/i, '.tmp.xlsx');
  XLSX.writeFile(wb, tempPath);
  fs.copyFileSync(tempPath, REPORT_PATH);
  fs.unlinkSync(tempPath);
}

function startStaticServerIfNeeded() {
  if (process.env.E2E_BASE_URL) return null;
  if (!fs.existsSync(path.join(BUILD_ROOT, 'index.html'))) {
    throw new Error(`Missing ${path.join(BUILD_ROOT, 'index.html')}. Run "flutter build web" before npm run test:e2e.`);
  }

  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.wasm': 'application/wasm',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
  };

  const server = http.createServer((req, res) => {
    const sanitized = decodeURIComponent((req.url || '/').split('?')[0]).replace(/^\/+/, '');
    const resolved = path.resolve(BUILD_ROOT, sanitized);
    if (!resolved.startsWith(BUILD_ROOT)) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }
    let target = resolved;
    if (fs.existsSync(target) && fs.statSync(target).isDirectory()) target = path.join(target, 'index.html');
    if (!fs.existsSync(target) || !fs.statSync(target).isFile()) target = path.join(BUILD_ROOT, 'index.html');
    res.writeHead(200, { 'Content-Type': mimeTypes[path.extname(target).toLowerCase()] || 'application/octet-stream' });
    fs.createReadStream(target).pipe(res);
  });

  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(DEFAULT_PORT, '127.0.0.1', () => {
      console.log(`Static web server running at ${BASE_URL}`);
      resolve(server);
    });
  });
}

async function main() {
  ensureReportDirs();
  const server = await startStaticServerIfNeeded();
  const options = new chrome.Options();
  if (HEADLESS) options.addArguments('--headless=new');
  options.addArguments('--disable-gpu', '--disable-dev-shm-usage', '--no-sandbox', '--window-size=1366,768');
  options.setPageLoadStrategy('none');

  const driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
  await driver.manage().setTimeouts({ pageLoad: 12000, script: 15000, implicit: 1000 });
  const cases = makeCases();
  const results = [];

  try {
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
        console.log(`PASS ${testCase.id} ${testCase.title}`);
      } catch (error) {
        const evidence = await screenshotOnFailure(driver, slugify(testCase.id));
        results.push({
          ...testCase,
          status: 'FAIL',
          actual: error && error.message ? error.message : String(error),
          durationMs: Date.now() - started,
          timestamp: new Date().toISOString(),
          evidence,
        });
        console.log(`FAIL ${testCase.id} ${testCase.title} :: ${results[results.length - 1].actual}`);
      }
      if (results.length % 10 === 0 || results.length === cases.length) writeReport(results, cases);
    }
  } finally {
    await driver.quit().catch(() => {});
    if (server) await new Promise((resolve) => server.close(resolve));
    writeReport(results, cases);
    console.log(`Report written: ${REPORT_PATH}`);
  }

  if (results.some((r) => r.status === 'FAIL')) process.exitCode = 1;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
