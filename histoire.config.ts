// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineConfig } from 'histoire'
import { HstVue } from '@histoire/plugin-vue'

export default defineConfig({
  setupFile: './app/frontend/stories/support/setupHistoire.ts',
  storyMatch: ['app/frontend/**/*.story.vue'],
  plugins: [HstVue()],
  vite: {
    server: {
      port: 3074,
    },
    logLevel: process.env.HISTOIRE_BUILD ? 'error' : 'info',
  },
  tree: {
    groups: [
      {
        id: 'common',
        title: 'Common',
        include: (file) => file.title.startsWith('Common'),
      },
      {
        id: 'modules',
        title: 'Modules',
      },
      {
        id: 'form',
        title: 'Form',
        include: (file) => file.title.startsWith('Field'),
      },
    ],
  },
})
