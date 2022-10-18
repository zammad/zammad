// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createRequire } from 'module'
import { defineConfig, type ResolvedConfig } from 'vite'
import VuePlugin from '@vitejs/plugin-vue'
import {
  createSvgIconsPlugin,
  type ViteSvgIconsPlugin,
} from 'vite-plugin-svg-icons'
import path from 'path'

import tsconfig from './tsconfig.base.json'

export default defineConfig(({ mode, command }) => {
  const isStory = Boolean(process.env.HISTOIRE)
  const isTesting = ['test', 'cypress'].includes(mode) || isStory
  const isBuild = command === 'build' && !isStory

  const require = createRequire(import.meta.url)

  const svgPlugin = createSvgIconsPlugin({
    // Specify the directory containing all icon assets assorted by sets.
    iconDirs: [
      path.resolve(
        __dirname,
        'app/frontend/shared/components/CommonIcon/assets',
      ),
    ],

    // Specify symbolId format to include directory as icon set and filename as icon name.
    symbolId: 'icon-[dir]-[name]',

    svgoOptions: {
      plugins: [{ name: 'preset-default' }],
    } as ViteSvgIconsPlugin['svgoOptions'],
  })

  if (isStory) {
    // Patch svg plugin for stories, because it's not working with SSR.
    const svgConfigResolved = svgPlugin.configResolved as (
      cfg: ResolvedConfig,
    ) => void
    svgConfigResolved({ command: 'build' } as ResolvedConfig)
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
    // TODO: Disable manual chunks for now, check if it's still neded with Vite 3.0.
    // plugins.push(ManualChunks())
  }

  return {
    esbuild: {
      target: tsconfig.compilerOptions.target,
    },
    resolve: {
      alias: {
        '@mobile': path.resolve(__dirname, 'app/frontend/apps/mobile'),
        '@shared': path.resolve(__dirname, 'app/frontend/shared'),
        '@tests': path.resolve(__dirname, 'app/frontend/tests'),
        '@stories': path.resolve(__dirname, 'app/frontend/stories'),
        '@cy': path.resolve(__dirname, '.cypress'),
        '@': path.resolve(__dirname, 'app/frontend'),
        '^vue-easy-lightbox$':
          'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.esm.min.js',
      },
    },
    server: {
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
    },
    plugins,
  }
})
