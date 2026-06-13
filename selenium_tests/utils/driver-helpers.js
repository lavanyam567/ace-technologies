'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Ace Technologies – Selenium Test Suite  ·  Shared Driver Utilities
// ─────────────────────────────────────────────────────────────────────────────

const { Builder, By, Key, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const CONFIG = require('../config/test-config');

/**
 * Build a configured Chrome WebDriver instance.
 * @param {object} [overrides]  Optional window-size override.
 */
async function buildDriver(overrides = {}) {
  const opts = new chrome.Options();
  if (CONFIG.browser.headless) opts.addArguments('--headless=new');
  const args = [
    ...CONFIG.browser.chromeArgs,
    `--window-size=${overrides.width || CONFIG.browser.windowSize.width},${
      overrides.height || CONFIG.browser.windowSize.height
    }`,
  ];
  opts.addArguments(...args);
  opts.setPageLoadStrategy('none');

  const driver = await new Builder()
    .forBrowser('chrome')
    .setChromeOptions(opts)
    .build();

  await driver.manage().setTimeouts({
    pageLoad: CONFIG.browser.pageLoadTimeout,
    script:   CONFIG.browser.scriptTimeout,
    implicit: CONFIG.browser.implicitTimeout,
  });

  return driver;
}

/** Wait for document.readyState to be complete/interactive. */
async function waitForAppReady(driver) {
  await driver
    .wait(async () => {
      const state = await driver.executeScript('return document.readyState');
      return state === 'interactive' || state === 'complete';
    }, CONFIG.timeouts.navigation)
    .catch(() => {});
  await wait(CONFIG.timeouts.flutterBoot);
}

/** Navigate to a URL and wait for the Flutter app to boot. */
async function openRoute(driver, route) {
  const url = new URL(route, CONFIG.app.baseUrl).toString();
  await driver.get(url);
  await waitForAppReady(driver);
}

/** Sleep helper. */
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

/** Collect all visible text + ARIA attributes from the page. */
async function pageText(driver) {
  return driver.executeScript(`
    if (!document.body) return "";
    const parts = [document.body.innerText || ""];
    for (const el of document.querySelectorAll(
        '[aria-label],[placeholder],[title],[alt],input,textarea,button')) {
      parts.push(
        el.getAttribute('aria-label') || '',
        el.getAttribute('placeholder') || '',
        el.getAttribute('title') || '',
        el.getAttribute('alt') || '',
        el.value || '',
        el.textContent || ''
      );
    }
    return parts.filter(Boolean).join("\\n");
  `);
}

const normalizeText = (t) =>
  String(t || '').replace(/\s+/g, ' ').trim().toLowerCase();

/** Assert page has more than 10 chars of readable text. */
async function assertReadablePage(driver) {
  await driver.wait(
    async () => normalizeText(await pageText(driver)).length > 10,
    CONFIG.timeouts.assertion,
    'Expected readable page text'
  );
}

/** Assert any of the supplied strings appears on the page (with scroll). */
async function assertAnyText(driver, expected) {
  const list   = Array.isArray(expected) ? expected : [expected];
  const needles = list.map(normalizeText);
  let scrolls  = 0;
  const initial = Date.now() + 2000;

  await driver.wait(async () => {
    const body = normalizeText(await pageText(driver));
    if (needles.some((n) => body.includes(n))) return true;
    if (Date.now() < initial) { await wait(200); return false; }
    if (scrolls < 12) { scrolls++; await scrollPage(driver); }
    return false;
  }, CONFIG.timeouts.assertion, `Expected any of: ${list.join(' | ')}`);
}

/** Assert ALL strings in the list appear on the page. */
async function assertAllText(driver, list) {
  for (const text of list) await assertAnyText(driver, text);
}

/** Scroll the page by one viewport height. */
async function scrollPage(driver, deltaY = 700) {
  await driver.findElement(By.css('body')).sendKeys(Key.PAGE_DOWN).catch(() => {});
  const rect = await driver.manage().window().getRect();
  await driver
    .actions({ async: true })
    .scroll(Math.floor(rect.width * 0.5), Math.floor(rect.height * 0.5), 0, deltaY)
    .perform()
    .catch(() => {});
  await wait(200);
}

/** Click an element by visible text / aria-label / role. */
async function clickText(driver, text, { strict = false } = {}) {
  const lower = normalizeText(text).replace(/'/g, "\\'");
  const xpath = `//*[@role='button' or self::button or self::a][
    contains(translate(normalize-space(.),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'${lower}') or
    contains(translate(@aria-label,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'${lower}')
  ]`;

  for (let attempt = 0; attempt < 10; attempt++) {
    const elements = await driver.findElements(By.xpath(xpath));
    for (const el of elements) {
      try {
        await driver.executeScript(
          'arguments[0].scrollIntoView({block:"center",inline:"center"});', el
        );
        await wait(100);
        if (await el.isDisplayed()) {
          await el.click().catch(() =>
            driver.executeScript('arguments[0].click();', el)
          );
          await wait(300);
          return;
        }
      } catch (_) {}
    }
    // Semantic fallback
    const sem = await driver.findElements(
      By.css(`[aria-label="${text.replace(/"/g, '\\"')}"]`)
    );
    if (sem.length) {
      await driver.executeScript(
        `arguments[0].dispatchEvent(new MouseEvent('click',{bubbles:true}));`, sem[0]
      ).catch(() => {});
      await wait(300);
      return;
    }
    await scrollPage(driver);
  }
  if (!strict) return; // soft-fail if not strict
  throw new Error(`Could not click element with text: "${text}"`);
}

/** Fill the first visible text input/textarea. */
async function fillFirstInput(driver, value) {
  const inputs = await driver.findElements(By.css('input:not([type=hidden]), textarea'));
  if (!inputs.length) throw new Error('No text input found');
  await inputs[0].sendKeys(Key.chord(Key.CONTROL, 'a'), Key.DELETE, value);
}

/** Fill an input matching a placeholder text. */
async function fillInputByPlaceholder(driver, placeholder, value) {
  const el = await driver.findElement(
    By.css(`input[placeholder*="${placeholder}"], textarea[placeholder*="${placeholder}"]`)
  );
  await el.clear();
  await el.sendKeys(value);
}

/** Take a screenshot to the evidence folder. */
async function screenshot(driver, name) {
  const fs   = require('fs');
  const path = require('path');
  fs.mkdirSync(CONFIG.paths.evidence, { recursive: true });
  const filepath = path.join(
    CONFIG.paths.evidence,
    `${name}-${Date.now()}.png`
  );
  try {
    const img = await driver.takeScreenshot();
    fs.writeFileSync(filepath, img, 'base64');
    return filepath;
  } catch (_) {
    return '';
  }
}

/** Set the viewport size. */
async function setViewport(driver, width, height) {
  await driver.manage().window().setRect({ width, height });
  await wait(400);
}

/** Get current page performance metrics via Navigation Timing API. */
async function getPerformanceMetrics(driver) {
  return driver.executeScript(`
    const t = window.performance && window.performance.timing;
    if (!t) return null;
    const nav = window.performance.getEntriesByType('navigation')[0];
    return {
      domContentLoaded: t.domContentLoadedEventEnd - t.navigationStart,
      pageLoad:         t.loadEventEnd - t.navigationStart,
      ttfb:             t.responseStart - t.navigationStart,
      domInteractive:   t.domInteractive - t.navigationStart,
      transferSize:     nav ? nav.transferSize : 0,
      encodedBodySize:  nav ? nav.encodedBodySize : 0,
    };
  `);
}

/** Check if a CSS selector exists on the page. */
async function elementExists(driver, cssSelector) {
  const els = await driver.findElements(By.css(cssSelector));
  return els.length > 0;
}

/** Get the page title. */
async function getTitle(driver) {
  return driver.getTitle();
}

/** Get current URL. */
async function getUrl(driver) {
  return driver.getCurrentUrl();
}

/** Execute JavaScript and return the result. */
async function executeJs(driver, script, ...args) {
  return driver.executeScript(script, ...args);
}

/** Wait for URL to contain a substring. */
async function waitForUrlContains(driver, substring, timeoutMs) {
  const timeout = timeoutMs || CONFIG.timeouts.assertion;
  await driver.wait(
    async () => (await getUrl(driver)).includes(substring),
    timeout,
    `URL did not contain "${substring}"`
  );
}

module.exports = {
  buildDriver,
  waitForAppReady,
  openRoute,
  wait,
  pageText,
  normalizeText,
  assertReadablePage,
  assertAnyText,
  assertAllText,
  scrollPage,
  clickText,
  fillFirstInput,
  fillInputByPlaceholder,
  screenshot,
  setViewport,
  getPerformanceMetrics,
  elementExists,
  getTitle,
  getUrl,
  executeJs,
  waitForUrlContains,
  By,
  Key,
  until,
};
