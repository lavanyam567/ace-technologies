const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

async function test() {
  const options = new chrome.Options();
  options.addArguments('--headless', '--disable-gpu', '--no-sandbox');
  const driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
  try {
    await driver.get('http://127.0.0.1:4173/products');
    
    // wait for app to be ready
    await driver.wait(async () => {
      const readyState = await driver.executeScript('return document.readyState');
      return readyState === 'interactive' || readyState === 'complete';
    }, 9000).catch(() => {});
    await new Promise(r => setTimeout(r, 2000));
    
    // Extractor
    const text = await driver.executeScript(`
      function extractText(node) {
        let text = "";
        if (node.nodeType === 3) {
          text += node.textContent + " ";
        }
        if (node.shadowRoot) {
          text += extractText(node.shadowRoot);
        }
        if (node.childNodes) {
          for (let child of node.childNodes) {
            text += extractText(child);
          }
        }
        return text;
      }
      return extractText(document);
    `);
    
    console.log("EXTRACTED TEXT:");
    console.log(text.trim().replace(/\\s+/g, ' '));
  } finally {
    await driver.quit();
  }
}
test();
