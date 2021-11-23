// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import VuePlugin from '@vitejs/plugin-vue'
import * as path from 'path'

export default defineConfig({
  resolve: {
    alias: {
      '@mobile': path.resolve(__dirname, 'app/frontend/apps/mobile'),
      '@common': path.resolve(__dirname, 'app/frontend/common'),
    },
  },
  plugins: [RubyPlugin(), VuePlugin()],
})
