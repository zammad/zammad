// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import initializeApp from '@mobile/initialize'
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'
import { defineSetupVue3 } from '@histoire/plugin-vue'
import { createRouter, createWebHistory } from 'vue-router'
import { h, createApp, type App } from 'vue'

const root = typeof window !== 'undefined' && window.document.documentElement

const initializeRouter = (app: App) => {
  // to avoid warning message
  delete app._context.components.RouterView
  delete app._context.components.RouterLink
  const router = createRouter({
    history: createWebHistory('/'),
    routes: [
      {
        path: '/:pathMatch(.*)*',
        component: {
          render() {
            return h('div')
          },
        },
      },
    ],
  })
  app.use(router)
}

const renderDynamics = () => {
  const dynamic = createApp({
    components: { DynamicInitializer },
    render() {
      return h(DynamicInitializer, {
        name: 'dialog',
        transition: {
          enterActiveClass: 'duration-300 ease-out',
          enterFromClass: 'opacity-0 translate-y-3/4',
          enterToClass: 'opacity-100 translate-y-0',
          leaveActiveClass: 'duration-200 ease-in',
          leaveFromClass: 'opacity-100 translate-y-0',
          leaveToClass: 'opacity-0 translate-y-3/4',
        },
      })
    },
  })
  initializeApp(dynamic)
  initializeRouter(dynamic)

  dynamic.mount('#dynamic')
}

if (root) {
  const getSandbox = () =>
    typeof document !== 'undefined' &&
    document.querySelector('#app > .__histoire-sandbox')
  const interval = setInterval(() => {
    const sandbox = getSandbox()
    if (sandbox) {
      clearInterval(interval)
      sandbox.classList.add('text-white')
      sandbox.classList.add('p-2')
      sandbox.classList.add('h-full')
      const dynamics = document.createElement('div')
      dynamics.setAttribute('id', 'dynamic')
      sandbox.appendChild(dynamics)
      renderDynamics()
    }
    if (typeof document === 'undefined') {
      clearInterval(interval)
    }
  }, 60)
  root.setAttribute('dir', 'ltr')
}

// let initialized = false

export const setupVue3 = defineSetupVue3(({ app }) => {
  // if (initialized) return
  // initialized = true

  initializeApp(app)
  initializeRouter(app)
})
