const { buildDriver, wait } = require('./utils/driver-helpers');

async function test() {
  const driver = await buildDriver();
  try {
    const size = await driver.getWindowSize();
    console.log('Window size:', size);
    
    const startX = Math.floor(size.width * 0.5);
    const startY = Math.floor(size.height * 0.6);
    const endY = Math.floor(size.height * 0.4);
    
    console.log(`Attempting scroll with button 0: startX=${startX}, startY=${startY}, endY=${endY}`);
    
    await driver.performActions([{
      type: 'pointer',
      id: 'finger1',
      parameters: { pointerType: 'touch' },
      actions: [
        { type: 'pointerMove', duration: 0, x: startX, y: startY },
        { type: 'pointerDown', button: 0 },
        { type: 'pointerMove', duration: 1000, x: startX, y: endY },
        { type: 'pointerUp', button: 0 }
      ]
    }]);
    console.log('Scroll with button: 0 succeeded!');
  } catch (err) {
    console.error('Scroll with button: 0 failed:', err.message);
  }

  try {
    const size = await driver.getWindowSize();
    const startX = Math.floor(size.width * 0.5);
    const startY = Math.floor(size.height * 0.6);
    const endY = Math.floor(size.height * 0.4);
    
    console.log(`Attempting scroll without button: startX=${startX}, startY=${startY}, endY=${endY}`);
    
    await driver.performActions([{
      type: 'pointer',
      id: 'finger1',
      parameters: { pointerType: 'touch' },
      actions: [
        { type: 'pointerMove', duration: 0, x: startX, y: startY },
        { type: 'pointerDown' },
        { type: 'pointerMove', duration: 1000, x: startX, y: endY },
        { type: 'pointerUp' }
      ]
    }]);
    console.log('Scroll without button succeeded!');
  } catch (err) {
    console.error('Scroll without button failed:', err.message);
  }

  await driver.deleteSession();
}

test();
