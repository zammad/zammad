// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mount, MountingOptions } from '@vue/test-utils'
import { merge } from 'lodash-es'
import {
  createRouter,
  createWebHistory,
  Router,
  RouteRecordRaw,
} from 'vue-router'
import CommonIcon from '@common/components/common/CommonIcon.vue'
import CommonLink from '@common/components/common/CommonLink.vue'
import { Plugin } from 'vue'
import { createTestingPinia } from '@pinia/testing'

interface ExtendedMountingOptions<Props> extends MountingOptions<Props> {
  router?: boolean
  store?: boolean
  routerRoutes?: RouteRecordRaw[]
}

const i18n = {
  t(source: string) {
    return source
  },
}

const plugins: Plugin[] = []

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

  const localWrapperOptions: ExtendedMountingOptions<Props> = merge(
    defaultWrapperOptions,
    wrapperOptions,
  )

  return mount(component, localWrapperOptions)
}

export default getWrapper
