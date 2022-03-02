// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import VuePlugin from '@vitejs/plugin-vue'
import viteSvgIcons from 'vite-plugin-svg-icons'
import type { OptimizeOptions } from 'svgo'
import * as path from 'path'

export default defineConfig({
  esbuild: {
    target: 'es2020', // Must stay in sync with tsconfig.json.
  },
  resolve: {
    alias: {
      '@mobile': path.resolve(__dirname, 'app/frontend/apps/mobile'),
      '@common': path.resolve(__dirname, 'app/frontend/common'),
      '@tests': path.resolve(__dirname, 'app/frontend/tests'),
    },
  },
  define: {
    VITE_TEST_MODE: !!process.env.VITEST || !!process.env.VITE_TEST_MODE,
  },
  test: {
    globals: true,
    setupFiles: ['./tests/vitest.setup.ts'],
    environment: 'jsdom',
  },
  plugins: [
    RubyPlugin(),
    VuePlugin(),
    viteSvgIcons({
      // Specify the icon folder to be cached
      iconDirs: [path.resolve(process.cwd(), 'public/assets/images/icons')],
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
                {
                  selector: "[fill='#BD0FE1']",
                  attributes: 'fill',
                },
                {
                  selector: "[fill='#BD10E0']",
                  attributes: 'fill',
                },
              ],
            },
          },
        ],
      } as OptimizeOptions,
    }),
  ],
})
