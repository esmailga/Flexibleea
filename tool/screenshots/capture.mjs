// Captures phone-sized screenshots of the demo build with the locally
// installed Chrome (puppeteer-core, no browser download).
import { mkdirSync } from 'node:fs';
import puppeteer from 'puppeteer-core';

const [base, outDir] = process.argv.slice(2);
const chrome = process.env.CHROME_PATH ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const shots = [
  ['onboarding', 'screen=onboarding'],
  ['login', 'screen=login'],
  ['explore', 'screen=explore'],
  ['details', 'screen=details'],
  ['profile', 'screen=profile'],
  ['people', 'screen=people'],
  ['listing-form', 'screen=form'],
  ['admin', 'screen=admin'],
  ['explore-dark', 'screen=explore&theme=dark'],
];

mkdirSync(outDir, { recursive: true });
const browser = await puppeteer.launch({
  executablePath: chrome,
  headless: true,
  args: ['--hide-scrollbars', '--force-color-profile=srgb'],
});

try {
  for (const [name, query] of shots) {
    const page = await browser.newPage();
    await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
    await page.goto(`${base}/?${query}`, { waitUntil: 'networkidle0', timeout: 120000 });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    // Let fonts, avatars and entrance animations finish.
    await new Promise((r) => setTimeout(r, 4500));
    await page.screenshot({ path: `${outDir}/${name}.png` });
    console.log(`captured ${name}`);
    await page.close();
  }
} finally {
  await browser.close();
}
