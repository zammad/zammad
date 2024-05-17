import { defineConfig } from 'cypress'
import { rm } from 'node:fs/promises'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { initPlugin as initVisualRegressionPlugin } from '@frsource/cypress-plugin-visual-regression-diff/plugins'
import pkg from '../../package.json' with { type: 'json' }

const dir = dirname(fileURLToPath(import.meta.url))

const isCYCI = !process.env.CY_OPEN
const root = resolve(dir, '../..')

// we don't need to optimize graphql and apollo
const skipDeps = ['graphql', 'apollo', '@tiptap/pm']

export default defineConfig({
  videosFolder: '.dev/cypress/videos',
  supportFolder: '.dev/cypress/support/index.js',
  fixturesFolder: '.dev/cypress/fixtures',
  downloadsFolder: '.dev/cypress/downloads',
  screenshotsFolder: '.dev/cypress/screenshots',
  videoCompression: false,
  env: {
    CY_CI: isCYCI,
    pluginVisualRegressionDiffConfig: {
      threshold: 0.02,
    },
    pluginVisualRegressionMaxDiffThreshold: 0.02,
  },
  component: {
    supportFile: '.dev/cypress/support/index.js',
    setupNodeEvents(on, config) {
      on('after:spec', (spec, results) => {
        if (results && results.stats.failures === 0 && results.video) {
          return rm(results.video)
        }
      })
      initVisualRegressionPlugin(on, config)
      on('before:browser:launch', (browser, launchOptions) => {
        if (browser?.family === 'chromium' && browser?.name !== 'electron') {
          launchOptions.args.push('--force-device-scale-factor=2')
        }
        return launchOptions
      })
    },
    devServer: {
      framework: 'vue',
      bundler: 'vite',
      viteConfig: {
        mode: 'cypress',
        root,
        configFile: resolve(dir, '../..', 'vite.config.mjs'),
        cacheDir: resolve(dir, 'node_modules', '.vite'),
        server: {
          fs: {
            strict: false,
          },
          hmr: true,
          ...(isCYCI && { watch: { ignored: ['**/*'] } }),
        },
        optimizeDeps: {
          entries: [
            '**/cypress/**/*.cy.ts',
            '!**/node_modules/**',
            '!**/*.d.ts',
          ],
          include: [
            // if you see cypress failing on some dependency, add it to skipDeps
            ...Object.keys(pkg.dependencies).filter(
              (name) => !skipDeps.some((dep) => name.includes(dep)),
            ),
          ],
        },
      },
    },
    // iPhone 12 viewport
    viewportWidth: 390,
    viewportHeight: 844,
    fileServerFolder: '..',
    indexHtmlFile: '.dev/cypress/support/component-index.html',
    specPattern: ['app/frontend/cypress/**/*.cy.{js,jsx,ts,tsx}'],
  },
  retries: 0,
})
