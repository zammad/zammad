// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import '@shared/initializer/translatableMarker'
import '@shared/styles/main.css'
import { app } from '@storybook/vue3'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import { createRouter, createWebHashHistory, type Router } from 'vue-router'
import { createApp } from 'vue'
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'
import initializeApp from '@mobile/initialize'

const dynamic = createApp({
  components: { DynamicInitializer },
  template: `
  <DynamicInitializer
    name="dialog"
    :transition="{
      enterActiveClass: 'duration-300 ease-out',
      enterFromClass: 'opacity-0 translate-y-3/4',
      enterToClass: 'opacity-100 translate-y-0',
      leaveActiveClass: 'duration-200 ease-in',
      leaveFromClass: 'opacity-100 translate-y-0',
      leaveToClass: 'opacity-0 translate-y-3/4',
    }"
  />
  `,
})

dynamic.mount('#dynamic')

initializeApp(app)
initializeApp(dynamic)

const router: Router = createRouter({
  history: createWebHashHistory(),
  routes: [],
})
app.use(router)

export default {
  actions: { argTypesRegex: '^on[A-Z].*' },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
}
