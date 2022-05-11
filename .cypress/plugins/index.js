// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const { startDevServer } = require('@cypress/vite-dev-server')
const { addMatchImageSnapshotPlugin } = require('cypress-image-snapshot/plugin')
const { rm } = require('fs/promises')
const { readFileSync } = require('fs')
const { resolve } = require('path')

module.exports = function plugin(on, config) {
  const pkgFile = readFileSync(resolve(__dirname, '../../package.json'), 'utf8')
  const pkg = JSON.parse(pkgFile)
  const cypressPkgFile = readFileSync(
    resolve(__dirname, '../package.json'),
    'utf8',
  )
  const cypressPkg = JSON.parse(cypressPkgFile)

  on('dev-server:start', (options) => {
    const isCI = !!process.env.CI
    const root = resolve(__dirname, '..', '..')
    const viteConfig = {
      mode: 'cypress',
      root,
      configFile: resolve(__dirname, '..', '..', 'vite.config.ts'),
      cacheDir: resolve(__dirname, '..', 'node_modules', '.vite'),
      server: {
        fs: {
          strict: false,
        },
        hmr: !isCI,
      },
      optimizeDeps: {
        entries: [
          '**/.cypress/utils/*.ts',
          '**/cypress/**/*.ts',
          '!**/node_modules/**',
          '!**/*.d.ts',
        ],
      },
    }
    return startDevServer({
      options: { ...options, config: { ...options.config, projectRoot: root } },
      viteConfig,
    })
  })
  // eslint-disable-next-line consistent-return
  on('after:spec', (spec, results) => {
    if (results && results.stats.failures === 0 && results.video) {
      return rm(results.video)
    }
  })
  addMatchImageSnapshotPlugin(on, config)
}
