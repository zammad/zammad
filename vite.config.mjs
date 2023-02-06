// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable security/detect-non-literal-fs-filename */

import { createRequire } from 'module'
import { defineConfig } from 'vite'
import VuePlugin from '@vitejs/plugin-vue'
import { createSvgIconsPlugin } from 'vite-plugin-svg-icons'
import { VitePWA } from 'vite-plugin-pwa'
import { resolve, dirname } from 'node:path'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import tsconfig from './tsconfig.base.json' assert { type: 'json' }

const dir = dirname(fileURLToPath(import.meta.url))

const SSL_PATH = resolve(dir, 'config', 'ssl')

export default defineConfig(({ mode, command }) => {
  const isStory = Boolean(process.env.HISTOIRE)
  const isTesting = ['test', 'cypress'].includes(mode) || isStory
  const isBuild = command === 'build' && !isStory

  const require = createRequire(import.meta.url)

  const svgPlugin = createSvgIconsPlugin({
    // Specify the directory containing all icon assets assorted by sets.
    iconDirs: [
      resolve(dir, 'app/frontend/shared/components/CommonIcon/assets'),
    ],

    // Specify symbolId format to include directory as icon set and filename as icon name.
    symbolId: 'icon-[dir]-[name]',

    svgoOptions: {
      plugins: [{ name: 'preset-default' }],
    },
  })

  if (isStory) {
    // Patch svg plugin for stories, because it's not working with SSR.
    const svgConfigResolved = svgPlugin.configResolved
    svgConfigResolved({ command: 'build' })
    delete svgPlugin.configResolved
    const { load } = svgPlugin
    svgPlugin.load = function fakeLoad(id) {
      // @ts-expect-error the plugin is not updated
      return load?.call(this, id, true)
    }
  }

  const plugins = [
    VuePlugin({
      template: {
        compilerOptions: {
          nodeTransforms:
            isTesting || !!process.env.VITE_TEST_MODE
              ? []
              : [require('./app/frontend/build/transforms/transformTestId')],
        },
      },
    }),
    svgPlugin,
  ]

  // Ruby plugin is not needed inside of the vitest context and has some side effects.
  if (!isTesting || isBuild) {
    const { default: RubyPlugin } = require('vite-plugin-ruby')
    // const ManualChunks = require('./app/frontend/build/manualChunks')

    plugins.push(RubyPlugin())
    plugins.push(
      ...VitePWA({
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
    // TODO: Disable manual chunks for now, check if it's still neded with Vite 3.0.
    // plugins.push(ManualChunks())
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

  return {
    esbuild: {
      target: tsconfig.compilerOptions.target,
    },
    resolve: {
      alias: {
        '@mobile': resolve(dir, 'app/frontend/apps/mobile'),
        '@shared': resolve(dir, 'app/frontend/shared'),
        '@tests': resolve(dir, 'app/frontend/tests'),
        '@stories': resolve(dir, 'app/frontend/stories'),
        '@cy': resolve(dir, '.cypress'),
        '@': resolve(dir, 'app/frontend'),
        '^vue-easy-lightbox$':
          'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.esm.min.js',
      },
    },
    server: {
      https,
      watch: {
        ignored: isTesting
          ? []
          : ['**/*.spec.*', '**/__tests__/**/*', 'app/frontend/tests/**/*'],
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
      testTimeout: 30_000,
      deps: {
        // TODO remove after https://github.com/ueberdosis/tiptap/pull/3521 is merged
        inline: ['@tiptap/extension-mention'],
      },
    },
    plugins,
  }
})
