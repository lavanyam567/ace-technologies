const { buildDriver, wait, pageText, openRoute, scrollPage } = require('./utils/driver-helpers');

async function test() {
  const driver = await buildDriver();
  try {
    console.log('Navigating to /about...');
    await openRoute(driver, '/about');
    await wait(2000);
    
    console.log('--- BEFORE SCROLL ---');
    console.log(await pageText(driver));
    
    for (let i = 1; i <= 6; i++) {
      console.log(`\n--- SCROLL ${i} ---`);
      // Perform a custom smaller swipe (65% to 35%)
      const size = await driver.getWindowSize();
      const startX = Math.floor(size.width * 0.5);
      const startY = Math.floor(size.height * 0.65);
      const endY = Math.floor(size.height * 0.35);
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
      await wait(1500);
      const text = await pageText(driver);
      console.log(text);
    }
  } catch (err) {
    console.error('Failed:', err);
  }
  await driver.deleteSession();
}

test();
