const { test, expect } = require('@playwright/test');

test('basic test', async ({ page }) => {
  await page.goto('https://nodejs.org/');
  await expect(page).toHaveTitle(/Node.js — Run JavaScript Everywhere/);
});
