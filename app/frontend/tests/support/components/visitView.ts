// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApolloClient } from '@vue/apollo-composable'
import { random } from 'lodash-es'

// import authenticationGuard from '#shared/router/guards/before/authentication.ts'
// import permissionGuard from '#shared/router/guards/before/permission.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import mockApolloClient from '../mock-apollo-client.ts'

import LayoutTestDesktopView from './LayoutTestDesktopView.vue'
import LayoutTestMobileView from './LayoutTestMobileView.vue'
import renderComponent, {
  getHistory,
  getTestRouter,
  type ExtendedMountingOptions,
} from './renderComponent.ts'

import type { NavigationGuard, RouteRecordRaw } from 'vue-router'

const isDesktop = await vi.hoisted(async () => {
  const { getTestAppName } = await import('./app.ts')
  return getTestAppName() === 'desktop'
})

vi.mock('#shared/server/apollo/client.ts', async () => {
  if (isDesktop) {
    const { mockedApolloClient } = await import(
      '#tests/graphql/builders/mocks.ts'
    )
    return {
      clearApolloClientStore: async () => {
        await mockedApolloClient.clearStore()
      },
      getApolloClient: () => mockedApolloClient,
    }
  }
  return {
    clearApolloClientStore: () => {
      return Promise.resolve()
    },
    getApolloClient: () => {
      return {
        cache: {
          gc: () => [],
        },
      }
    },
  }
})

Object.defineProperty(window, 'fetch', {
  value: (path: string) => {
    throw new Error(`calling fetch on ${path}`)
  },
  writable: true,
  configurable: true,
})

const html = String.raw

interface VisitViewOptions extends ExtendedMountingOptions<unknown> {
  mockApollo?: boolean
  setLocale?: boolean
}

const { routes } = isDesktop
  ? await import('#desktop/router/index.ts')
  : await import('#mobile/router/index.ts')

// remove LayoutMain layout, keep only actual content
if (routes.at(-1)?.name === 'Main') {
  const [mainRoutes] = routes.splice(routes.length - 1, 1)

  routes.push(...(mainRoutes.children as RouteRecordRaw[]), {
    path: '/testing-environment',
    component: {
      template: '<div></div>',
    },
  })
}

// Always reset again before each renderComponent call. With this we
// have an initial route for each test.
const routerBeforeGuards: NavigationGuard[] = []

// TODO: disable some stuff for now, because it will break a lot of test.
// const routerBeforeGuards = [authenticationGuard, permissionGuard]
if (isDesktop) {
  // Always reset again before each renderComponent call. With this we
  // have an initial route for each test.

  //   const { default: systemSetupInfo } = await import(
  //     '#desktop/router/guards/before/systemSetupInfo.ts'
  //   )
  //   routerBeforeGuards.push(systemSetupInfo)
  const { default: activeTaskbarTab } = await import(
    '#desktop/router/guards/before/activeTaskbarTab.ts'
  )
  routerBeforeGuards.push(activeTaskbarTab)
}

export const visitView = async (
  href: string,
  // rely on new way to mock apollo in desktop by default
  options: VisitViewOptions = { mockApollo: !isDesktop, setLocale: isDesktop },
) => {
  if (options.mockApollo) {
    mockApolloClient([])
  } else if (isDesktop) {
    // automocking is enabled when this file is imported because it happens on the top level
    await import('#tests/graphql/builders/mocks.ts')
  }

  // Reset the initial navigation state and the initial route.
  const testKey = random()

  useNotifications().clearAllNotifications()

  const history = getHistory()
  history.replace(href)

  const view = renderComponent(
    {
      template: html` <LayoutTest${isDesktop
        ? 'DesktopView'
        : 'MobileView'} />`,
      components: {
        LayoutTestDesktopView,
        LayoutTestMobileView,
      },
    },
    {
      store: true,
      router: true,
      form: true,
      unmount: true,
      routerRoutes: routes,
      routerBeforeGuards,
      propsData: {
        testKey,
      },
      ...options,
    },
  )

  const { client } = useApolloClient()
  await client.clearStore()

  const router = getTestRouter()

  // we don't call router.replace(href) here because it's called by the router plugin when mounting
  // and it gets the correct href from the `history` object
  await router.isReady()

  if (options.setLocale) {
    await useLocaleStore().setLocale()
  }

  return view
}
