const percySnapshot = require('@percy/webdriverio');

const baseUrl = 'http://localhost:1313';

async function click(selector) {
  const elem = await $(selector);
  await elem.waitForDisplayed();
  await elem.click();
}

describe('stuff', () => {
  it('goto homepage', async () => {
    await browser.url(baseUrl);
    await percySnapshot('homepage');
  });

  it('goto blog', async () => {
    await browser.url(baseUrl);
    await click('=Blog');
    await percySnapshot('/blog');
  });
});

