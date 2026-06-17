const { buildDriver, wait, pageText } = require('./utils/driver-helpers');

async function test() {
  const driver = await buildDriver();
  try {
    console.log('Navigating to /about...');
    await clickText(driver, 'Home');
    await clickText(driver, 'About Us');
    await wait(2000);

    const size = await driver.getWindowSize();
    const startX = Math.floor(size.width * 0.5);
    const startY = Math.floor(size.height * 0.8);
    const endY = Math.floor(size.height * 0.2);

    for (let i = 0; i < 4; i++) {
      console.log(`[Swipe ${i+1}] Swiping from 80% to 20%: startY=${startY}, endY=${endY}`);
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
      console.log(`After scroll ${i+1}, has Muralidharan P?`, text.includes('Muralidharan P'));
      if (text.includes('Muralidharan P')) {
        console.log('--- FOUND IT! FULL TEXT ---');
        console.log(text);
        break;
      }
    }
  } catch (err) {
    console.error('Multiple swipes failed:', err);
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
