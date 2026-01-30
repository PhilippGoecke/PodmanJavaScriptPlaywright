FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests curl wget gnupg ca-certificates \
  && apt install -y --no-install-recommends --no-install-suggests fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libcups2 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 libwayland-client0 libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 xvfb \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
#COPY package*.json ./
RUN echo '{\n\
    "name": "playwright-podman-tests",\n\
    "version": "1.0.0",\n\
    "description": "Playwright tests running in Podman",\n\
    "scripts": {\n\
        "test": "playwright test",\n\
        "test:headed": "playwright test --headed",\n\
        "test:debug": "playwright test --debug"\n\
    },\n\
    "keywords": ["playwright", "testing", "e2e"],\n\
    "author": "",\n\
    "license": "MIT",\n\
    "devDependencies": {\n\
        "@playwright/test": "^1.40.0"\n\
    }\n\
}' > package.json
# Create a package-lock.json file
RUN npm install

# Install Playwright
RUN npm ci && npx playwright install --with-deps
#RUN npx playwright install chromium firefox webkit

# Copy test files
COPY tests/ ./tests/
# Example test file (tests/example.spec.js):
# const { test, expect } = require('@playwright/test');
#
# test('basic test', async ({ page }) => {
#   await page.goto('https://example.com');
#   await expect(page).toHaveTitle(/Example Domain/);
# });
#COPY playwright.config.js ./
# Create example playwright.config.js
RUN echo "const { defineConfig, devices } = require('@playwright/test');\n\
\n\
module.exports = defineConfig({\n\
    testDir: './tests',\n\
    fullyParallel: true,\n\
    forbidOnly: !!process.env.CI,\n\
    retries: process.env.CI ? 2 : 0,\n\
    workers: process.env.CI ? 1 : undefined,\n\
    reporter: 'html',\n\
    use: {\n\
        trace: 'on-first-retry',\n\
        screenshot: 'only-on-failure',\n\
    },\n\
    projects: [\n\
        {\n\
            name: 'chromium',\n\
            use: { ...devices['Desktop Chrome'] },\n\
        },\n\
        {\n\
            name: 'firefox',\n\
            use: { ...devices['Desktop Firefox'] },\n\
        },\n\
        {\n\
            name: 'webkit',\n\
            use: { ...devices['Desktop Safari'] },\n\
        },\n\
    ],\n\
});" > playwright.config.js

# Run tests
CMD ["npx", "playwright", "test"]
