// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-restricted-imports */

/// <reference types="vitest" />

import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import VuePlugin from '@vitejs/plugin-vue'
import { createSvgIconsPlugin } from 'vite-plugin-svg-icons'
import type { OptimizeOptions } from 'svgo'
import * as path from 'path'

import tsconfig from './tsconfig.json'
import TransformTestId from './app/frontend/tests/transforms/transformTestId'

export default defineConfig(({ mode }) => ({
  esbuild: {
    target: tsconfig.compilerOptions.target,
  },
  resolve: {
    alias: {
      '@mobile': path.resolve(__dirname, 'app/frontend/apps/mobile'),
      '@common': path.resolve(__dirname, 'app/frontend/common'),
      '@tests': path.resolve(__dirname, 'app/frontend/tests'),
      '@stories': path.resolve(__dirname, 'app/frontend/stories'),
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
    ['test', 'storybook'].includes(mode) ? [] : RubyPlugin(),
    VuePlugin({
      template: {
        compilerOptions: {
          nodeTransforms: ['test', 'storybook'].includes(mode)
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
}))
