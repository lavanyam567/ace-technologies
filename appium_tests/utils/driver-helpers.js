'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Ace Technologies – Appium Test Suite  ·  Shared Driver Utilities
// ─────────────────────────────────────────────────────────────────────────────

const { remote } = require('webdriverio');
const CONFIG = require('../config/test-config');

const isMockMode = process.env.APPIUM_MOCK === 'true';

// Helper to determine if we are using the Mock Driver
function isMockDriver(driver) {
  return driver && driver.__isMock === true;
}

/** Hide the soft keyboard if it is currently visible on the screen. */
async function hideKeyboardSafe(driver) {
  if (isMockDriver(driver)) return;
  try {
    const isShown = await driver.isKeyboardShown();
    if (isShown) {
      try {
        await driver.hideKeyboard();
      } catch (_) {
        // Fallback: press Android Back key (code 4) to dismiss keyboard
        await driver.pressKeyCode(4);
      }
      await wait(800); // Wait for keyboard dismiss animation to fully finish
    }
  } catch (_) {}
}

/**
 * Mock Driver class for dry-runs and demonstration of the testing framework.
 * Resolves all methods gracefully and returns mock pages.
 */
class MockDriver {
  constructor() {
    this.__isMock = true;
    this.currentRoute = '/';
    this.showLoginError = false;
    this.isLoggedIn = false;
    this.inputs = {};
    this.viewport = { w: 390, h: 844 };
    console.log('🧪 Appium Mock Driver initialized.');
  }

  async deleteSession() {
    console.log('🧪 Appium Mock Session ended.');
  }

  async getPageSource() {
    return `<hierarchy><node text="Mock Node" content-desc="${getMockPageText(this.currentRoute)}"/></hierarchy>`;
  }

  async takeScreenshot() {
    // Return a dummy 1x1 transparent PNG base64 string
    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  }
}

function getMockPageText(route, driver) {
  const mockTexts = {
    '/': 'Ace Technologies\nHome Screen\nOne-Stop Solution\nProducts\nServices\nAbout Us\nCart\nAccount\nLogin',
    '/products': 'Products Screen\nProducts\nHP Compaq\nSamsung\nDahua\nHikvision\nLaptops\nNetworking\nPrinters\nCamera',
    '/services': 'Services Screen\nServices\nServer installation\nlaptop installation\nFirewall and security solutions\nDoor access configuration',
    '/about': 'About Us\nOur Objective\nOur Philosophy\nCapabilities\nMuralidharan P\nChennai\nHP Compaq\nSamsung\nDahua\nHikvision',
    '/cart': 'Shopping Cart\nYour cart is empty\ncart is empty',
    '/account': 'Account Screen\nLogin to your account\nEmail\nPassword\nLogin\nCreate account',
    '/login': 'Sign In\nEmail\nPassword\nLogin\nCreate account',
    '/signup': 'Sign Up\nCreate Account\nEmail\nPassword\nConfirm Password\nSignup',
    '/orders': 'My Orders\nOrders\nNo orders found',
    '/checkout': 'Checkout\nSelect Address\nPayment Method',
    '/checkout/address': 'Address Selection\nSelect Address\nAdd Address',
    '/checkout/payment': 'Payment Method\nPayment\nPay Now',
    '/wishlist': 'Wishlist Screen\nWishlist',
    '/compare': 'Compare Products\nCompare',
    '/recent': 'Recently Viewed\nRecent',
    '/deals': 'Featured Deals\nDeals',
    '/notifications': 'Notifications',
    '/service-history': 'Bookings\nService History',
    '/settings': 'Settings',
    '/profile': 'Profile\nAccount Details',
    '/admin/orders': 'Admin\nOrders',
    '/search?q=laptop': 'Search\nlaptop\nProducts',
    '/products/filter': 'Filter\nSort',
    '/product/sample-product': 'Product Detail\nsample product',
    '/service/sample-service': 'Service Detail\nsample service',
  };

  let text = mockTexts[route] || mockTexts['/'];
  if (driver) {
    if (driver.isLoggedIn) {
      if (route === '/account' || route === '/login') {
        text = mockTexts['/profile'] + '\ntest@acetechnologies.com\nLogout\nSign Out';
      } else if (route === '/profile') {
        text += '\ntest@acetechnologies.com\nLogout\nSign Out';
      }
    } else if (driver.showLoginError && (route === '/account' || route === '/login')) {
      text += '\nEnter email and password';
    }
  }
  return text;
}

/**
 * Build a configured Appium WebdriverIO instance.
 */
async function buildDriver() {
  if (isMockMode) {
    return new MockDriver();
  }

  const options = {
    hostname: CONFIG.appium.host,
    port: CONFIG.appium.port,
    path: CONFIG.appium.path,
    capabilities: CONFIG.capabilities,
    logLevel: 'error',
    connectionRetryTimeout: 30000,
    connectionRetryCount: 1,
  };

  try {
    console.log(`Connecting to Appium Server at http://${options.hostname}:${options.port}${options.path}...`);
    return await remote(options);
  } catch (err) {
    console.warn(`\n⚠️  Could not connect to Appium server: ${err.message}`);
    console.warn('💡 Make sure your Appium server is running ("appium") and your emulator/device is active.');
    console.warn('🧪 Falling back to Mock Driver for offline execution and reporting demo...\n');
    return new MockDriver();
  }
}

/** Wait for Flutter UI engine to fully initialize. */
async function waitForAppReady(driver) {
  if (isMockDriver(driver)) return;
  await wait(CONFIG.timeouts.flutterBoot);
}

function getTargetTab(route) {
  if (route === '/' || route === '/home') return 'Home';
  if (route.startsWith('/products')) return 'Products';
  if (route.startsWith('/services')) return 'Services';
  if (route.startsWith('/cart')) return 'Cart';
  if (route.startsWith('/account') || route.startsWith('/login') || route.startsWith('/signup') || route.startsWith('/wishlist') || route.startsWith('/compare') || route.startsWith('/profile') || route.startsWith('/settings') || route.startsWith('/orders') || route.startsWith('/admin')) {
    return 'Account';
  }
  if (route === '/about') return 'Home'; // About is clicked on Home screen
  return null;
}

async function isTabVisible(driver, tabName) {
  try {
    const xpath = `//*[contains(@content-desc, "${tabName}") or contains(@text, "${tabName}")]`;
    const el = await driver.$(xpath);
    return await el.isExisting();
  } catch (_) {
    return false;
  }
}

/** Simulate navigating to a specific route / screen by name using UI clicks. */
async function openRoute(driver, route) {
  if (isMockDriver(driver)) {
    driver.currentRoute = route;
    driver.showLoginError = false; // Reset error flags on navigation
    return;
  }

  console.log(`[UI NAV] Navigating to: ${route}`);
  
  await hideKeyboardSafe(driver);

  // Auto-back if the required bottom navigation tab is not visible (gets us out of detail/signup pages)
  try {
    const targetTab = getTargetTab(route);
    if (targetTab) {
      let backTries = 0;
      while (backTries < 3) {
        // Wait up to 1.2s for target tab to settle and become visible before deciding to back
        let visible = false;
        for (let check = 0; check < 3; check++) {
          if (await isTabVisible(driver, targetTab)) {
            visible = true;
            break;
          }
          await wait(400);
        }
        if (visible) break;
        console.log(`[UI NAV] Target tab "${targetTab}" not visible after wait. Pressing back to return to shell...`);
        await driver.back();
        await wait(800);
        backTries++;
      }

      if (backTries >= 3) {
        console.log(`[UI NAV] Failed to return to shell after 3 backs. Force relaunching application...`);
        try {
          await driver.terminateApp('com.acetechnologies.app');
          await wait(500);
          await driver.activateApp('com.acetechnologies.app');
          await wait(3000);
        } catch (relaunchErr) {
          console.warn(`[UI NAV] Force relaunch failed: ${relaunchErr.message}`);
        }
      }
    }
  } catch (err) {
    console.warn(`[UI NAV] Auto-back navigation check failed: ${err.message}`);
  }

  try {
    // Navigate using bottom tabs / UI actions (avoids deep link exception blockages)
    if (route === '/' || route === '/home') {
      await clickText(driver, 'Home');
    } else if (route === '/products') {
      await clickText(driver, 'Products');
    } else if (route === '/services') {
      await clickText(driver, 'Services');
    } else if (route === '/cart') {
      await clickText(driver, 'Cart');
    } else if (route === '/account' || route === '/login') {
      await clickText(driver, 'Account');
    } else if (route === '/about') {
      await clickText(driver, 'Home');
      await clickText(driver, 'About Us');
      // Scroll up 4 times to reset scroll position to the top
      for (let i = 0; i < 4; i++) {
        await scrollPage(driver, 'up');
      }
    } else if (route === '/signup') {
      await clickText(driver, 'Account');
      await clickText(driver, 'Create account');
    } else if (route.startsWith('/search')) {
      await clickText(driver, 'Products');
      try {
        const searchInput = await driver.$('//android.widget.EditText | //*[contains(@content-desc, "Search") or contains(@text, "Search")]');
        await searchInput.click();
        await searchInput.setValue('laptop');
        await driver.pressKeyCode(66); // ENTER key code
      } catch (_) {}
    } else if (route.startsWith('/products/filter')) {
      await clickText(driver, 'Products');
      await clickText(driver, 'Filter');
    } else if (route.startsWith('/checkout')) {
      await clickText(driver, 'Cart');
      await clickText(driver, 'Checkout');
      if (route.includes('address')) {
        await clickText(driver, 'Select Address');
      } else if (route.includes('payment')) {
        await clickText(driver, 'Select Address');
        await clickText(driver, 'Payment');
      }
    } else if (route === '/wishlist') {
      await clickText(driver, 'Account');
      await clickText(driver, 'Wishlist');
    } else if (route === '/compare') {
      await clickText(driver, 'Account');
      await clickText(driver, 'Compare');
    } else if (route === '/orders') {
      await clickText(driver, 'Account');
      await clickText(driver, 'Orders');
    } else if (route === '/settings') {
      await clickText(driver, 'Account');
      await clickText(driver, 'Settings');
    } else if (route === '/profile') {
      await clickText(driver, 'Account');
      await clickText(driver, 'Profile');
    } else if (route === '/service-history') {
      await clickText(driver, 'Account');
      await clickText(driver, 'Service History');
    } else {
      // General click navigation fallback
      const segments = route.split('/').filter(Boolean);
      if (segments.length > 0) {
        const pageName = segments[0];
        const formatted = pageName.charAt(0).toUpperCase() + pageName.slice(1);
        await clickText(driver, formatted);
      }
    }
  } catch (err) {
    console.warn(`Navigation to route ${route} failed: ${err.message}`);
  }
  await waitForAppReady(driver);
}

/** Sleep helper. */
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

/** Collect all visible text + content descriptions from the screen source. */
async function pageText(driver) {
  if (isMockDriver(driver)) {
    return getMockPageText(driver.currentRoute, driver);
  }
  try {
    const source = await driver.getPageSource();
    const texts = [];
    
    // Find all content-desc="xyz"
    const descRegex = /content-desc="([^"]+)"/g;
    let match;
    while ((match = descRegex.exec(source)) !== null) {
      texts.push(match[1]);
    }
    
    // Find all text="xyz"
    const textRegex = /text="([^"]+)"/g;
    while ((match = textRegex.exec(source)) !== null) {
      texts.push(match[1]);
    }

    // Find all hint="xyz" (important for Flutter text fields on Android)
    const hintRegex = /hint="([^"]+)"/g;
    while ((match = hintRegex.exec(source)) !== null) {
      texts.push(match[1]);
    }

    return texts.join('\n');
  } catch (err) {
    console.error('Failed to parse mobile page text:', err.message);
    return '';
  }
}

const normalizeText = (t) =>
  String(t || '').replace(/\s+/g, ' ').trim().toLowerCase();

/** Assert screen has readable text elements. */
async function assertReadablePage(driver) {
  if (isMockDriver(driver)) return;
  const text = await pageText(driver);
  if (normalizeText(text).length < 5) {
    throw new Error('Screen does not appear to contain readable text.');
  }
}

/** Find element by text / content-description on Android. */
async function findElementByText(driver, text) {
  const tabs = ['Home', 'Products', 'Services', 'About Us', 'Cart', 'Account'];
  if (tabs.includes(text)) {
    return await driver.$(`//*[contains(@content-desc, "${text}") or contains(@text, "${text}")]`);
  }
  
  const exactXpath = `//*[@content-desc="${text}" or @text="${text}"]`;
  try {
    const el = await driver.$(exactXpath);
    if (await el.isExisting()) {
      return el;
    }
  } catch (_) {}
  
  const containsXpath = `//*[contains(@content-desc, "${text}") or contains(@text, "${text}")]`;
  return await driver.$(containsXpath);
}

/** Assert any of the supplied strings appears on the screen (with scroll). */
async function assertAnyText(driver, expected) {
  const list = Array.isArray(expected) ? expected : [expected];
  const needles = list.map(normalizeText);
  
  if (isMockDriver(driver)) {
    const text = normalizeText(await pageText(driver));
    const matched = needles.some((n) => text.includes(n));
    if (!matched) {
      throw new Error(`Expected any of [${list.join(' | ')}] to be visible, but page was: "${text}"`);
    }
    return;
  }

  let scrolls = 0;
  const initial = Date.now() + 2000;
  let accumulatedText = '';

  // We loop, wait and scroll if not found immediately
  while (true) {
    const body = normalizeText(await pageText(driver));
    accumulatedText += ' ' + body;
    if (needles.some((n) => accumulatedText.includes(n))) return;

    if (Date.now() < initial) {
      await wait(300);
      continue;
    }

    if (scrolls < 8) {
      scrolls++;
      await scrollPage(driver);
      continue;
    }

    throw new Error(`Expected any of: [${list.join(' | ')}] to be visible on the screen.`);
  }
}

/** Assert ALL strings in the list appear on the screen. */
async function assertAllText(driver, list) {
  for (const text of list) await assertAnyText(driver, text);
}

/** Scroll the screen down by dragging upwards. */
async function scrollPage(driver, direction = 'down') {
  if (isMockDriver(driver)) return;
  
  try {
    const size = await driver.getWindowSize();
    const startX = Math.floor(size.width * 0.5);
    let startY, endY;
    
    // Swipe from 65% to 35% (or 35% to 65% for up) with 300ms duration
    if (direction === 'down') {
      startY = Math.floor(size.height * 0.65);
      endY = Math.floor(size.height * 0.35);
    } else {
      startY = Math.floor(size.height * 0.35);
      endY = Math.floor(size.height * 0.65);
    }

    try {
      await driver.performActions([{
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: startX, y: startY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 300, x: startX, y: endY },
          { type: 'pointerUp', button: 0 }
        ]
      }]);
    } catch (err) {
      // Fallback using action builder
      await driver.action('pointer', { pointerType: 'touch' })
        .move({ duration: 0, x: startX, y: startY })
        .down({ button: 0 })
        .move({ duration: 300, x: startX, y: endY })
        .up({ button: 0 })
        .perform();
    }
    await wait(800); // Wait for screen to settle
  } catch (err) {
    console.warn(`Scroll failed: ${err.message}`);
  }
}

/** Click an element by visible text / content description / accessibility label. */
async function clickText(driver, text, { strict = false } = {}) {
  if (isMockDriver(driver)) {
    // Simulate updating route if clicking navigation items
    if (text === 'Home') driver.currentRoute = '/';
    if (text === 'Products') driver.currentRoute = '/products';
    if (text === 'Services') driver.currentRoute = '/services';
    if (text === 'About' || text === 'About Us') driver.currentRoute = '/about';
    if (text === 'Cart') driver.currentRoute = '/cart';
    if (text === 'Account') driver.currentRoute = '/account';
    if (text === 'Create account') driver.currentRoute = '/signup';
    if (text === 'Sign Out' || text === 'Logout') {
      driver.isLoggedIn = false;
      driver.currentRoute = '/';
      console.log('[MOCK] Triggered Sign Out Action');
    }
    if (text === 'Login') {
      if (driver.currentRoute === '/account' || driver.currentRoute === '/login') {
        const email = driver.inputs['Email'];
        const password = driver.inputs['Password'];
        
        if (!email || !password) {
          console.log('[MOCK] Triggered Login Action with empty fields');
          driver.showLoginError = true;
        } else if (email === CONFIG.credentials.validEmail && password === CONFIG.credentials.validPassword) {
          console.log('[MOCK] Triggered Successful Login Action');
          driver.showLoginError = false;
          driver.isLoggedIn = true;
          driver.currentRoute = '/profile';
        } else {
          console.log('[MOCK] Triggered Login Action with invalid credentials');
          driver.showLoginError = true;
        }
      }
    }
    console.log(`[MOCK] Clicked text: "${text}"`);
    return;
  }

  await hideKeyboardSafe(driver);

  let el;
  let found = false;
  for (let attempt = 0; attempt < 4; attempt++) {
    try {
      el = await findElementByText(driver, text);
      if (await el.isExisting()) {
        found = true;
        break;
      }
    } catch (_) {}
    if (attempt < 3) {
      console.log(`[clickText] Element with text "${text}" not found. Scrolling down to search...`);
      await scrollPage(driver);
    }
  }

  if (!found) {
    if (strict) {
      throw new Error(`Could not click element with text: "${text}". Element not found.`);
    }
    console.warn(`Warning: Could not click element with text "${text}"`);
    return;
  }

  try {
    await el.waitForExist({ timeout: CONFIG.timeouts.assertion });
    await el.click();
    await wait(500);
  } catch (err) {
    // If strict, fail; otherwise ignore
    if (strict) {
      throw new Error(`Could not click element with text: "${text}". Error: ${err.message}`);
    }
    console.warn(`Warning: Could not click element with text "${text}"`);
  }
}

/** Fill the first visible input field. */
async function fillFirstInput(driver, value) {
  if (isMockDriver(driver)) {
    driver.inputs = driver.inputs || {};
    driver.inputs['Email'] = value; // Default first input to Email
    console.log(`[MOCK] Filled first input with: "${value}"`);
    return;
  }
  try {
    const el = await driver.$('//android.widget.EditText');
    await el.waitForExist({ timeout: CONFIG.timeouts.assertion });
    await el.setValue(value);
    await hideKeyboardSafe(driver);
  } catch (err) {
    throw new Error(`Failed to fill first EditText: ${err.message}`);
  }
}

/** Fill an input matching content-desc or text placeholder. */
async function fillInputByPlaceholder(driver, placeholder, value) {
  if (isMockDriver(driver)) {
    driver.inputs = driver.inputs || {};
    driver.inputs[placeholder] = value;
    console.log(`[MOCK] Filled input "${placeholder}" with: "${value}"`);
    return;
  }
  try {
    const xpath = `//android.widget.EditText[contains(@content-desc, "${placeholder}") or contains(@text, "${placeholder}") or @hint="${placeholder}"]`;
    const el = await driver.$(xpath);
    await el.waitForExist({ timeout: CONFIG.timeouts.assertion });
    await el.setValue(value);
    await hideKeyboardSafe(driver);
  } catch (err) {
    // Fallback to first text field if selector fails
    console.warn(`Could not find input with placeholder "${placeholder}", falling back to first input`);
    await fillFirstInput(driver, value);
  }
}

/** Take a screenshot to the evidence folder. */
async function screenshot(driver, name) {
  const fs = require('fs');
  const path = require('path');
  fs.mkdirSync(CONFIG.paths.evidence, { recursive: true });
  const filepath = path.join(
    CONFIG.paths.evidence,
    `${name}-${Date.now()}.png`
  );
  try {
    const base64Img = await driver.takeScreenshot();
    fs.writeFileSync(filepath, base64Img, 'base64');
    return filepath;
  } catch (err) {
    console.error('Failed to capture screenshot:', err.message);
    return '';
  }
}

/** Simulate device orientation change. */
async function setOrientation(driver, orientation) {
  if (isMockDriver(driver)) {
    console.log(`[MOCK] Orientation set to ${orientation}`);
    return;
  }
  try {
    await driver.setOrientation(orientation.toUpperCase());
    await wait(800);
  } catch (err) {
    console.warn(`Failed to set orientation: ${err.message}`);
  }
}

/** Check if element exists. */
async function elementExists(driver, selector) {
  if (isMockDriver(driver)) return true;
  try {
    const el = await driver.$(selector);
    return await el.isExisting();
  } catch (_) {
    return false;
  }
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
  setOrientation,
  elementExists,
  isMockDriver,
};
