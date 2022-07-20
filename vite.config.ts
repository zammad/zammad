// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-restricted-imports */

/// <reference types="vitest" />

import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import VuePlugin from '@vitejs/plugin-vue'
import { createSvgIconsPlugin } from 'vite-plugin-svg-icons'
import type { OptimizeOptions } from 'svgo'
import * as path from 'path'

import tsconfig from './tsconfig.base.json'
import TransformTestId from './app/frontend/build/transforms/transformTestId'
import ManualChunks from './app/frontend/build/manual-chunks.mjs'

export default defineConfig(({ mode, command }) => {
  const isTesting = ['test', 'storybook', 'cypress'].includes(mode)
  const isBuild = command === 'build'

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
      },
    },
    define: {
      VITE_TEST_MODE: !!process.env.VITEST || !!process.env.VITE_TEST_MODE,
    },
    test: {
      globals: true,
      setupFiles: ['app/frontend/tests/vitest.setup.ts'],
      environment: 'jsdom',
    },
    plugins: [
      // Ruby plugin is not needed inside of the vitest context and has some side effects.
      isTesting && !isBuild ? [] : [...RubyPlugin(), ManualChunks()],
      VuePlugin({
        template: {
          compilerOptions: {
            nodeTransforms:
              isTesting || !!process.env.VITE_TEST_MODE
                ? []
                : [TransformTestId],
          },
        },
      }),
      createSvgIconsPlugin({
        // Specify the icon folder to be cached
        iconDirs: [
          path.resolve(
            process.cwd(),
            `${
              mode === 'storybook' ? '../public' : 'public'
            }/assets/images/icons`,
          ),
        ],
        // Specify symbolId format
        symbolId: 'icon-[dir]-[name]',
        svgoOptions: {
          plugins: [
            { name: 'preset-default' },
            {
              name: 'removeAttributesBySelector',
              params: {
                selectors: [
                  {
                    selector: "[fill='#50E3C2']",
                    attributes: 'fill',
                  },
                  // TODO: we need to add a own plugin or add some identifier to the svg files, to add the same functionality
                  // like we have in the old gulp script (fill='#50E3C2'] + parent fill='none' should be removed).
                ],
              },
            },
            {
              name: 'convertColors',
              params: {
                currentColor: /(#BD0FE1|#BD10E0)/,
              },
            },
          ],
        } as OptimizeOptions,
      }),
    ],
  }
})
