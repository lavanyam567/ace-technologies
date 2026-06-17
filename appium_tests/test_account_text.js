const { buildDriver, wait, pageText } = require('./utils/driver-helpers');

async function test() {
  const driver = await buildDriver();
  try {
    console.log('Navigating to /account...');
    // Ensure we are logged out
    await clickText(driver, 'Home');
    await clickText(driver, 'Account');
    await wait(2000);

    const text = await pageText(driver);
    console.log('--- ACCOUNT PAGE TEXT ---');
    console.log(text);

    console.log('--- FULL PAGE SOURCE ---');
    const source = await driver.getPageSource();
    console.log(source);
  } catch (err) {
    console.error('Failed:', err);
  }
  await driver.deleteSession();
}

async function clickText(driver, text) {
  try {
    const xpath = `//*[@content-desc="${text}" or @text="${text}" or contains(@content-desc, "${text}") or contains(@text, "${text}")]`;
    const el = await driver.$(xpath);
    await el.click();
  } catch (err) {
    console.error(`Click failed for ${text}:`, err.message);
  }
}

test();
