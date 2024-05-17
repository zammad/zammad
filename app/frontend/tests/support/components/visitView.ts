// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApolloClient } from '@vue/apollo-composable'
import { random } from 'lodash-es'

// import authenticationGuard from '#shared/router/guards/before/authentication.ts'
// import permissionGuard from '#shared/router/guards/before/permission.ts'

import { useLocaleStore } from '#shared/stores/locale.ts'

import mockApolloClient from '../mock-apollo-client.ts'

import { getTestAppName } from './app.ts'
import LayoutTestDesktopView from './LayoutTestDesktopView.vue'
import LayoutTestMobileView from './LayoutTestMobileView.vue'
import renderComponent, {
  getTestRouter,
  type ExtendedMountingOptions,
} from './renderComponent.ts'

import type { RouteRecordRaw } from 'vue-router'

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
}

const isDesktop = getTestAppName() === 'desktop'

export const visitView = async (
  href: string,
  // rely on new way to mock apollo in desktop by default
  options: VisitViewOptions = { mockApollo: !isDesktop, setLocale: isDesktop },
) => {
  const { routes } = isDesktop
    ? await import('#desktop/router/index.ts')
    : await import('#mobile/router/index.ts')

  if (options.mockApollo) {
    vi.mock('#shared/server/apollo/client.ts', () => {
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

    mockApolloClient([])
  } else if (isDesktop) {
    // automocking is enabled when this file is imported because it happens on the top level
    await import('#tests/graphql/builders/mocks.ts')
  }

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

  // const routerBeforeGuards = [authenticationGuard, permissionGuard]
  // if (isDesktop) {
  //   const { default: systemSetupInfo } = await import(
  //     '#desktop/router/guards/before/systemSetupInfo.ts'
  //   )
  //   routerBeforeGuards.push(systemSetupInfo)
  // }

  const testKey = random()

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
      // TODO: disable for now and handle in seperate change
      // routerBeforeGuards,
      propsData: {
        testKey,
      },
      ...options,
    },
  )

  const { client } = useApolloClient()
  await client.clearStore()

  const router = getTestRouter()

  await router.replace(href)

  if (options.setLocale) {
    await useLocaleStore().setLocale()
  }

  return view
}
