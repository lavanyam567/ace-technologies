'use strict';

const CONFIG = require('../config/test-config');
const {
  openRoute,
  pageText,
  assertReadablePage,
  assertAnyText,
  clickText,
  fillInputByPlaceholder,
  wait,
} = require('./driver-helpers');

async function logoutIfNeeded(driver) {
  await openRoute(driver, '/account');
  const text = await pageText(driver);
  if (/logout|sign out/i.test(text)) {
    await clickText(driver, 'Logout');
    await wait(600);
  }
  if (driver && driver.__isMock) {
    driver.inputs = {};
    driver.showLoginError = false;
  }
}

async function loginIfNeeded(driver) {
  await openRoute(driver, '/account');
  const text = await pageText(driver);
  if (/logout|sign out|profile/i.test(text)) {
    return;
  }

  await fillInputByPlaceholder(driver, 'Email', CONFIG.credentials.validEmail);
  await fillInputByPlaceholder(driver, 'Password', CONFIG.credentials.validPassword);
  await clickText(driver, 'Login');
  await wait(1000);
  await assertAnyText(driver, ['Profile', 'Logout', 'Account']);
}

async function prepareRoute(driver, screen) {
  if (screen && screen.loginRequired) {
    await loginIfNeeded(driver);
  } else {
    await logoutIfNeeded(driver);
  }
  await openRoute(driver, screen.route);
}

async function visitAndAssert(driver, screen) {
  await prepareRoute(driver, screen);
  await assertReadablePage(driver);
  await assertAnyText(driver, screen.anchors);
}

module.exports = {
  loginIfNeeded,
  logoutIfNeeded,
  prepareRoute,
  visitAndAssert,
};
