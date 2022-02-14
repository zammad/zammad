// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mount, MountingOptions } from '@vue/test-utils'
import { merge } from 'lodash-es'
import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router'
import { plugin as formPlugin } from '@formkit/vue'
import { buildFormKitPluginConfig } from '@common/form'
import CommonIcon from '@common/components/common/CommonIcon.vue'
import CommonLink from '@common/components/common/CommonLink.vue'
import { Plugin } from 'vue'
import { createTestingPinia } from '@pinia/testing'
import { i18n } from '@common/utils/i18n'

// TODO: some things can be handled differently: https://test-utils.vuejs.org/api/#config-global

interface ExtendedMountingOptions<Props> extends MountingOptions<Props> {
  router?: boolean
  routerRoutes?: RouteRecordRaw[]
  store?: boolean
  form?: boolean
}

const plugins: (Plugin | [Plugin, ...unknown[]])[] = []

const defaultWrapperOptions: ExtendedMountingOptions<unknown> = {
  shallow: true,
  global: {
    components: {
      CommonIcon,
      CommonLink,
    },
    mocks: {
      i18n,
    },
    stubs: {},
    plugins,
  },
}

let routerInitialized = false

const initializeRouter = (routes?: RouteRecordRaw[]) => {
  let localRoutes: RouteRecordRaw[] = [
    {
      name: 'Dashboard',
      path: '/',
      component: {
        template: 'Welcome to zammad.',
      },
    },
    {
      name: 'Example',
      path: '/example',
      component: {
        template: 'This is a example page.',
      },
    },
  ]

  // Use only the default routes, if nothing was given.
  if (routes) {
    localRoutes = routes
  }

  const router = createRouter({
    history: createWebHistory(),
    routes: localRoutes,
  })

  plugins.push(router)

  defaultWrapperOptions.global ||= {}
  Object.assign(defaultWrapperOptions.global.stubs, {
    RouterLink: false,
  })

  routerInitialized = true
}

let storeInitialized = false

const initializeStore = () => {
  plugins.push(createTestingPinia())
  storeInitialized = true
}

let formInitialized = false

const initializeForm = () => {
  plugins.push([formPlugin, buildFormKitPluginConfig()])
  defaultWrapperOptions.shallow = false

  formInitialized = true

  defaultWrapperOptions.props ||= {}

  // Reset the defult of 20ms for testing.
  defaultWrapperOptions.props.delay = 0
}

const getWrapper: typeof mount = <Props>(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  component: any,
  wrapperOptions?: ExtendedMountingOptions<Props>,
) => {
  // Store and Router needs only to be initalized once for a test suit.
  if (wrapperOptions?.router && !routerInitialized) {
    initializeRouter(wrapperOptions?.routerRoutes)
  }
  if (wrapperOptions?.store && !storeInitialized) {
    initializeStore()
  }
  if (wrapperOptions?.form && !formInitialized) {
    initializeForm()
  }

  const localWrapperOptions: ExtendedMountingOptions<Props> = merge(
    defaultWrapperOptions,
    wrapperOptions,
  )

  return mount(component, localWrapperOptions)
}

export default getWrapper
