// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApolloClient } from '@vue/apollo-composable'
import { random } from 'lodash-es'
import type { RouteRecordRaw } from 'vue-router'
import LayoutTest from './LayoutTest.vue'
import mockApolloClient from '../mock-apollo-client.ts'
import renderComponent, {
  getTestRouter,
  type ExtendedMountingOptions,
} from './renderComponent.ts'
import { getTestAppName } from './app.ts'

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

// TODO: for desktop app `LayoutTest` should have an abstract header component instead of mobile one
export const visitView = async (
  href: string,
  // rely on new way to mock apollo in desktop by default
  options: VisitViewOptions = { mockApollo: !isDesktop },
) => {
  const { routes } = isDesktop
    ? await import('#desktop/router/index.ts')
    : await import('#mobile/router/index.ts')

  if (options.mockApollo) {
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

  const testKey = random()

  const view = renderComponent(
    {
      template: html`<LayoutTest />`,
      components: { LayoutTest },
    },
    {
      store: true,
      router: true,
      form: true,
      unmount: true,
      routerRoutes: routes,
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

  return view
}
