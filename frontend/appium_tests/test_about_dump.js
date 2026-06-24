const { buildDriver, wait, pageText, openRoute } = require('./utils/driver-helpers');

async function test() {
  const driver = await buildDriver();
  try {
    console.log('Navigating to /about...');
    await openRoute(driver, '/about');
    await wait(2000);
    const text = await pageText(driver);
    console.log('--- DUMP OF ABOUT PAGE ---');
    console.log(text);
    console.log('--------------------------');
  } catch (err) {
    console.error('Failed:', err);
  }
  await driver.deleteSession();
}

test();
