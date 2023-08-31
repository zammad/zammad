// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/
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
import tsconfig from './tsconfig.base.json' assert { type: 'json' }

const dir = dirname(fileURLToPath(import.meta.url))

const SSL_PATH = resolve(homedir(), '.localhost')

// eslint-disable-next-line sonarjs/cognitive-complexity
export default defineConfig(({ mode, command }) => {
  const isStory = Boolean(process.env.HISTOIRE)
  const isTesting = ['test', 'cypress'].includes(mode) || isStory
  const isBuild = command === 'build' && !isStory

  const require = createRequire(import.meta.url)

  const plugins = [
    VuePlugin({
      template: {
        compilerOptions: {
          nodeTransforms:
            isTesting || !!process.env.VITE_TEST_MODE
              ? []
              : [require('./app/frontend/build/transforms/transformTestId.js')],
        },
      },
    }),
    svgIconsPlugin(),
  ]

  // Ruby plugin is not needed inside of the vitest context and has some side effects.
  if (!isTesting || isBuild) {
    const { default: RubyPlugin } = require('vite-plugin-ruby')
    const ManualChunks = require('./app/frontend/build/manualChunks.js')

    plugins.push(RubyPlugin())
    plugins.push(
      ...VitePWA({
        disable: isTesting || !!process.env.VITE_TEST_MODE,
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
    plugins.push(ManualChunks())
  }

  let https = false

  // vite-ruby controlls this variable, it's either "true" or "false"
  if (process.env.VITE_RUBY_HTTPS === 'true') {
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
  } else if (isStory) {
    publicDir = resolve(dir, 'app/frontend/public-build')
  }

  return {
    publicDir,
    esbuild: {
      target: isTesting ? 'esnext' : tsconfig.compilerOptions.target,
    },
    resolve: {
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
      VITE_TEST_MODE: !!process.env.VITEST || !!process.env.VITE_TEST_MODE,
    },
    test: {
      globals: true,
      // narrowing down test folder speeds up fast-glob in Vitest
      dir: 'app/frontend',
      setupFiles: ['app/frontend/tests/vitest.setup.ts'],
      environment: 'jsdom',
      clearMocks: true,
      css: false,
      testTimeout: process.env.CI ? 30_000 : 5_000,
      unstubGlobals: true,
      server: {
        deps: {
          // TODO remove after https://github.com/ueberdosis/tiptap/pull/3521 is merged
          inline: ['@tiptap/extension-mention'],
        },
      },
      onConsoleLog(log) {
        if (log.includes('Not implemented: navigation')) return false
      },
    },
    plugins,
  }
})
