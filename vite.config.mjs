// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createRequire } from 'module'
import { readFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'os'

import tailwindcss from '@tailwindcss/vite'
import VuePlugin from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'

import { discoverAddonWeaveRules } from './app/frontend/build/addonWeave/discoverRules.mjs'
import addonWeavePlugin from './app/frontend/build/addonWeave/plugin.mjs'
import svgIconsPlugin from './app/frontend/build/iconsPlugin.mjs'
import { discoverSkinMarkerClashes } from './app/frontend/build/skinMarker/discoverClashes.mjs'
import skinMarkerPlugin from './app/frontend/build/skinMarker/plugin.mjs'
import { vendorChunkGroups } from './app/frontend/build/vendorChunks.mjs'

const dir = dirname(fileURLToPath(import.meta.url))

const SSL_PATH = resolve(homedir(), '.local/state/localhost.rb')

const isEnvBooleanSet = (value) => ['true', '1'].includes(value)

// The HMR websocket cannot ride the Rails asset proxy (no upgrade support), so the client is
// pointed directly at the Vite port. A proxy that forwards websocket upgrades (see
// .devcontainer/with-caddy) sets VITE_HMR_SAME_ORIGIN to keep it on the page origin instead.
// `clientPort` must be an own property either way, or vite-plugin-ruby forces the Vite port.
const hmrClientOptions = () => {
  if (isEnvBooleanSet(process.env.VITE_HMR_SAME_ORIGIN)) {
    return { clientPort: undefined }
  }

  return {
    host: process.env.VITE_RUBY_HOST || 'localhost',
    clientPort: Number(process.env.VITE_RUBY_PORT || 3036),
  }
}

export default defineConfig(async ({ mode, command }) => {
  const isTesting = mode === 'test'
  const isBuild = command === 'build'

  const require = createRequire(import.meta.url)

  // Build-time addon weave: discover every installed addon's *.weave.mjs manifest
  // and rewrite the targeted core SFC source before the Vue compiler runs.
  const addonWeaveRules = await discoverAddonWeaveRules()

  const plugins = [
    // enforce: 'pre' → both run before VuePlugin compiles the SFC.
    addonWeavePlugin(addonWeaveRules),
    // Auto-stamp data-zammad-target on native SFC roots — the stable custom-CSS
    // hook. Skipped under test, where it would perturb component DOM snapshots.
    ...(isTesting || isEnvBooleanSet(process.env.VITE_TEST_MODE)
      ? []
      : [skinMarkerPlugin(discoverSkinMarkerClashes())]),
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
        // The worker caches nothing, so the manifest the plugin would inject is left out.
        injectManifest: { injectionPoint: undefined },
      }),
    )
  }

  if (isTesting) {
    // make sure timezone is always correct - in CLI and in the extension
    process.env.TZ = 'utc'
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
    build: {
      rolldownOptions: {
        output: {
          codeSplitting: { groups: vendorChunkGroups },
        },
      },
    },
    resolve: {
      preserveSymlinks: isEnvBooleanSet(process.env.PRESERVE_SYMLINKS),
      alias: [
        {
          find: '^vue-easy-lightbox$',
          replacement: 'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.esm.min.js',
        },
        // vue3-draggable-resizable ships CommonJS, whose `require('vue')` resolves to the CJS
        // build that includes the template compiler. The runtime build is enough.
        ...(isBuild ? [{ find: /^vue$/, replacement: 'vue/dist/vue.runtime.esm-bundler.js' }] : []),
        // In non-test builds, alias fake-timers to a tiny shim so Vite doesn't resolve Node core deps
        ...(isTesting
          ? []
          : [
              {
                find: '@sinonjs/fake-timers',
                replacement: resolve(dir, 'app/frontend/build/shims/fake-timers.ts'),
              },
            ]),
      ],
    },
    server: {
      https,
      ws: hmrClientOptions(),
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
    plugins,
  }
})
