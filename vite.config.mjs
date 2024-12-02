// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable security/detect-non-literal-fs-filename */

import { createRequire } from 'module'
import { defineConfig } from 'vite'
import VuePlugin from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'
import { resolve, dirname } from 'node:path'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { homedir } from 'os'
import svgIconsPlugin from './app/frontend/build/iconsPlugin.mjs'
import ManualChunksPlugin from './app/frontend/build/manualChunks.mjs'
import tsconfig from './tsconfig.base.json' with { type: 'json' }

const dir = dirname(fileURLToPath(import.meta.url))

const SSL_PATH = resolve(homedir(), '.local/state/localhost.rb')

const isEnvBooleanSet = (value) => {
  if (value === 'true' || value === '1') {
    return true;
  }
  else if (value === 'false' || value === '0') {
    return false;
  }

  return false;
}

// eslint-disable-next-line sonarjs/cognitive-complexity
export default defineConfig(({ mode, command }) => {
  const isTesting = ['test', 'cypress'].includes(mode)
  const isBuild = command === 'build'

  const require = createRequire(import.meta.url)

  const plugins = [
    VuePlugin({
      template: {
        compilerOptions: {
          nodeTransforms:
            isTesting || isEnvBooleanSet(process.env.VITE_TEST_MODE)
              ? []
              : [require('./app/frontend/build/transforms/transformTestId.js')],
        },
      },
    }),
    svgIconsPlugin(),
  ]

  if (!isTesting || isBuild) {
    // Ruby plugin is not needed inside of the vitest context and has some side effects.
    const { default: RubyPlugin } = require('vite-plugin-ruby')
    plugins.push(RubyPlugin())

    plugins.push(
      ...VitePWA({
        disable: isTesting || isEnvBooleanSet(process.env.VITE_TEST_MODE),
        // should be generated on ruby side
        manifest: false,
        registerType: 'prompt',
        srcDir: 'apps/mobile/sw',
        filename: 'sw.ts',
        includeManifestIcons: false,
        injectRegister: null,
        strategies: 'injectManifest',
      }),
    )
    plugins.push(ManualChunksPlugin())
  }

  let https = false

  // vite-ruby controlls this variable, it's either "true" or "false"
  if (isEnvBooleanSet(process.env.VITE_RUBY_HTTPS)) {
    const SSL_CERT = readFileSync(resolve(SSL_PATH, 'localhost.crt'))
    const SSL_KEY = readFileSync(resolve(SSL_PATH, 'localhost.key'))

    https = {
      cert: SSL_CERT,
      key: SSL_KEY,
    }
  }

  let publicDir

  if (!isBuild) {
    publicDir = resolve(dir, 'public')
  }

  return {
    publicDir,
    esbuild: {
      target: isTesting ? 'esnext' : tsconfig.compilerOptions.target,
    },
    resolve: {
      preserveSymlinks: isEnvBooleanSet(process.env.PRESERVE_SYMLINKS),
      alias: {
        '^vue-easy-lightbox$':
          'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.esm.min.js',
      },
    },
    server: {
      https,
      watch: {
        ignored: isTesting
          ? []
          : [
              '**/*.spec.*',
              '**/__tests__/**/*',
              (path) =>
                !path.includes('app/frontend') ||
                path.includes('frontend/tests'),
            ],
      },
    },
    define: {
      VITE_TEST_MODE: isEnvBooleanSet(process.env.VITEST) || isEnvBooleanSet(process.env.VITE_TEST_MODE),
    },
    test: {
      globals: true,
      // narrowing down test folder speeds up fast-glob in Vitest
      dir: 'app/frontend',
      setupFiles: ['app/frontend/tests/vitest.setup.ts'],
      environment: 'jsdom',
      clearMocks: true,
      css: false,
      testTimeout: isEnvBooleanSet(process.env.CI) ? 30_000 : 5_000,
      unstubGlobals: true,
      onConsoleLog(log) {
        if (log.includes('Not implemented: navigation') || log.includes('<Suspense> is an experimental feature')) return false
      },
    },
    plugins,
  }
})
