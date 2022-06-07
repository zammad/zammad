// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { RouteRecordRaw } from 'vue-router'
import mockApolloClient from '../mock-apollo-client'
import renderComponent, { getRouter } from './renderComponent'

Object.defineProperty(window, 'fetch', {
  value: (path: string) => {
    throw new Error(`calling fetch on ${path}`)
  },
  writable: true,
  configurable: true,
})

const html = String.raw

export const visitView = async (href: string) => {
  const { routes } = await import('@mobile/router')

  mockApolloClient([])

  // remove LayoutMain layout, keep only actual content
  if (routes.at(-1)?.name === 'Main') {
    const [mainRoutes] = routes.splice(routes.length - 1, 1)

    routes.push(...(mainRoutes.children as RouteRecordRaw[]))
  }

  const view = renderComponent(
    {
      template: html`<RouterView />`,
    },
    {
      store: true,
      router: true,
      form: true,
      unmount: true,
      routerRoutes: routes,
    },
  )

  const router = getRouter()

  await router.replace(href)

  return view
}
