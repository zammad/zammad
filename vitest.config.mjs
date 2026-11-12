// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createRequire } from 'node:module'
import { dirname, join, resolve } from 'node:path'

import { playwright } from '@vitest/browser-playwright'
import { defineConfig } from 'vitest/config'

import {
  moveMouseAwayCommand,
  routeRequestCommand,
  unrouteRequestCommand,
} from './app/frontend/tests/browser/commands.mts'
import viteConfig from './vite.config.mjs'

const require = createRequire(import.meta.url)

const isEnvBooleanSet = (value) => ['true', '1'].includes(value)

const isCI = isEnvBooleanSet(process.env.CI)

// Start a local server with `pnpm playwright:server`.
const playwrightServerUrl = process.env.PLAYWRIGHT_SERVER_URL || 'ws://localhost:4444/'

export default defineConfig(async (env) => ({
  ...(await viteConfig(env)),
  test: {
    // narrowing down test folder speeds up fast-glob in Vitest
    root: './app/frontend',
    clearMocks: true,
    unstubGlobals: true,
    onConsoleLog(log) {
      if (
        log.includes('Not implemented: navigation') ||
        log.includes('<Suspense> is an experimental feature')
      )
        return false
    },
    projects: [
      {
        extends: true,
        test: {
          name: 'unit',
          globals: true,
          exclude: ['**/node_modules/**', '**/.git/**', '**/*.browser.spec.ts', 'build/**'],
          setupFiles: ['./tests/vitest.setup.ts'],
          environment: 'jsdom',
          pool: 'vmForks',
          env: {
            SA11Y_RULESET: 'full',
          },
          css: false,
          testTimeout: isCI ? 30_000 : 5_000,
          // Persistent cache between reruns, invalidates if any dependency is updated.
          // Vitest doesn't cache files with `import.meta.glob` inside, so it might be a good
          // idea to put them all inside as few files as possible just for a small perf boost.
          // The perf difference is noticeable when running a single/few tests, but has
          // negligible impact when running the whole suite due to parallelisation.
          fsModuleCache: true,
          // Node v25+ enables experimental webstorage by default (stability: release candidate).
          // Without --localstorage-file, Node provides localStorage as an empty object (no methods).
          // This conflicts with jsdom's full localStorage implementation needed for tests.
          ...(parseInt(process.versions.node, 10) >= 25
            ? { execArgv: ['--no-experimental-webstorage'] }
            : {}),
          alias: [
            // ESM version of date-fns exports a lot of extra files which takes 500ms to load on M4 Mac
            // CJS version takes ~175ms which is also a lot, but not as much
            {
              find: /^date-fns$/,
              replacement: join(dirname(require.resolve('date-fns/package.json')), 'index.cjs'),
            },
          ],
        },
      },
      {
        extends: true,
        test: {
          name: 'build',
          include: ['build/**/*.spec.?(c|m)[jt]s'],
          environment: 'node',
          // The VM pools hand a require()d ES module to CommonJS code without `__esModule`, which breaks
          // the code generator packages: their CommonJS builds require the ESM-only auto-bind.
          pool: 'forks',
          testTimeout: isCI ? 30_000 : 5_000,
        },
      },
      {
        extends: true,
        test: {
          name: 'browser',
          // The waits and the mocker log read these from `import.meta.env`; the browser has no `process.env`.
          env: {
            CI: process.env.CI ?? '',
            VITEST_LOG_GQL_FACTORY: process.env.VITEST_LOG_GQL_FACTORY ?? '',
          },
          include: ['**/*.browser.spec.ts'],
          setupFiles: ['./tests/browser/setup.ts'],
          testTimeout: isCI ? 30_000 : 10_000,
          browser: {
            enabled: true,
            headless: true,
            // Always a Playwright server container, so that screenshots do not depend on the host.
            //   `<loopback>` lets its browser reach the Vitest server on this machine's localhost.
            provider: playwright({
              connectOptions: { wsEndpoint: playwrightServerUrl, exposeNetwork: '<loopback>' },
            }),
            instances: [{ browser: 'chromium' }],
            // iPhone 12, as the screenshots show the fields of the mobile view.
            viewport: { width: 390, height: 844 },
            testerHtmlPath: './tests/browser/tester.html',
            commands: {
              moveMouseAway: moveMouseAwayCommand,
              routeRequest: routeRequestCommand,
              unrouteRequest: unrouteRequestCommand,
            },
            locators: {
              testIdAttribute: 'data-test-id',
            },
            expect: {
              toMatchScreenshot: {
                // Without the platform of the Node process, which says nothing about the browser
                //   in the container: the reference screenshots are shared by all developers and CI.
                resolveScreenshotPath: ({
                  root,
                  testFileDirectory,
                  screenshotDirectory,
                  testFileName,
                  arg,
                  browserName,
                  ext,
                }) =>
                  resolve(
                    root,
                    testFileDirectory,
                    screenshotDirectory,
                    testFileName,
                    `${arg}-${browserName}${ext}`,
                  ),
                comparatorName: 'pixelmatch',
                comparatorOptions: {
                  // Chromium sometimes rasterizes a single edge pixel of a floating label differently.
                  allowedMismatchedPixels: 10,
                },
              },
            },
          },
        },
      },
    ],
  },
}))
