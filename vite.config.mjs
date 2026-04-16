// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/// <reference types="vitest/config" />

import { createRequire } from 'module'
import { readFileSync } from 'node:fs'
import { resolve, dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'os'

import tailwindcss from '@tailwindcss/vite'
import VuePlugin from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'

import svgIconsPlugin from './app/frontend/build/iconsPlugin.mjs'

const dir = dirname(fileURLToPath(import.meta.url))

const SSL_PATH = resolve(homedir(), '.local/state/localhost.rb')

const isEnvBooleanSet = (value) => ['true', '1'].includes(value)

export default defineConfig(({ mode, command }) => {
  const isTesting = ['test', 'cypress'].includes(mode)
  const isBuild = command === 'build'

  const require = createRequire(import.meta.url)

  const plugins = [
    tailwindcss(),
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
      // TODO: Remove the following line once the related upstream TailwindCSS issue has been addressed,
      //   since it can mask potential syntax errors.
      //   https://github.com/tailwindlabs/tailwindcss/issues/16582
      logOverride: { 'css-syntax-error': 'silent' },
    },
    build: {
      rollupOptions: {
        output: {
          manualChunks: {
            lodash: ['lodash-es'],
            vue: ['vue', 'vue-router', 'pinia'],
            datepicker: ['@vuepic/vue-datepicker'],
            linkifyjs: ['linkifyjs', 'linkify-string'],
            graphql: [
              'graphql',
              // 🚨 'graphql-ruby-client',
              // Important: don't include the package root here, it pulls in the Node-only `sync` entry
              // which imports fs/path/crypto/http/... and triggers Vite "externalized for browser" warnings.
              'graphql-ruby-client/subscriptions/ActionCableLink',
              'graphql-tag',
              '@apollo/client',
              '@vue/apollo-composable',
              '@rails/actioncable',
            ],
            formkit: [
              '@formkit/core',
              '@formkit/dev',
              // '@formkit/drag-and-drop', # is not used in mobile
              '@formkit/i18n',
              '@formkit/inputs',
              '@formkit/rules',
              '@formkit/tailwindcss',
              '@formkit/themes',
              '@formkit/utils',
              '@formkit/validation',
              '@formkit/vue',
            ],
          },
        },
      },
    },
    resolve: {
      preserveSymlinks: isEnvBooleanSet(process.env.PRESERVE_SYMLINKS),
      alias: {
        '^vue-easy-lightbox$': 'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.esm.min.js',
        // In non-test builds, alias fake-timers to a tiny shim so Vite doesn't resolve Node core deps
        ...(isTesting
          ? {}
          : {
              '@sinonjs/fake-timers': resolve(dir, 'app/frontend/build/shims/fake-timers.ts'),
            }),
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
              (path) => !path.includes('app/frontend') || path.includes('frontend/tests'),
            ],
      },
    },
    define: {
      VITE_TEST_MODE:
        isEnvBooleanSet(process.env.VITEST) || isEnvBooleanSet(process.env.VITE_TEST_MODE),
    },
    test: {
      globals: true,
      // narrowing down test folder speeds up fast-glob in Vitest
      root: './app/frontend',
      setupFiles: ['./tests/vitest.setup.ts'],
      environment: 'jsdom',
      env: {
        SA11Y_RULESET: 'full',
      },
      clearMocks: true,
      css: false,
      testTimeout: isEnvBooleanSet(process.env.CI) ? 30_000 : 5_000,
      unstubGlobals: true,
      // Node v25+ enables experimental webstorage by default (stability: release candidate).
      // Without --localstorage-file, Node provides localStorage as an empty object (no methods).
      // This conflicts with jsdom's full localStorage implementation needed for tests.
      ...(parseInt(process.versions.node, 10) >= 25 ? { execArgv: ['--no-experimental-webstorage'] } : {}),
      onConsoleLog(log) {
        if (
          log.includes('Not implemented: navigation') ||
          log.includes('<Suspense> is an experimental feature')
        )
          return false
      },
      // perf improvements
      server: {
        deps: {
          // vue-datepicker imports from date-fns and we don't want it to import ES version
          inline: ['@vuepic/vue-datepicker'],
        },
      },
      alias: [
        // ESM version of date-fns exports a lot of extra files which takes 500ms to load on M4 Mac
        // CJS version takes ~175ms which is also a lot, but not as much
        {
          find: /^date-fns$/,
          replacement: join(dirname(require.resolve('date-fns/package.json')), 'index.cjs'),
        },
      ],
      experimental: {
        // persistent cache between reruns, invalidates if any dependency is updated
        // vitest doesn't cache files with `import.meta.glob` inside, so it might be a good
        // idea to put them all inside as few files as possible just for a small perf boost
        // the perf difference is noticible when running a single/a few tests, but has
        // negligible impact when running the whole suite due to parallelisation
        fsModuleCache: true,
      },
    },
    plugins,
  }
})
