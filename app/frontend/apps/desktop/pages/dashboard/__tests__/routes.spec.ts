// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import dashboardRoutes from '../routes.ts'

// Keep the real paths, names, guards and meta, but not the views: this is about where the URL lands.
const withStubbedViews = (routes: RouteRecordRaw[]): RouteRecordRaw[] =>
  routes.map((route) => ({
    ...route,
    ...('component' in route && { component: { template: '<div />' } }),
  })) as RouteRecordRaw[]

const createTestRouter = () =>
  createRouter({
    history: createWebHistory('/desktop'),
    routes: [
      ...withStubbedViews(dashboardRoutes),
      { path: '/tickets/view', name: 'TicketOverview', component: { template: '<div />' } },
    ],
  })

describe('dashboard route', () => {
  it.each(['/', '/dashboard'])('opens the dashboard on %s', async (path) => {
    mockApplicationConfig({ dashboard: true })

    const router = createTestRouter()
    await router.push(path)

    expect(router.currentRoute.value.name).toBe('Dashboard')
  })

  it.each(['/', '/dashboard'])(
    'opens the overviews on %s while the dashboard is turned off',
    async (path) => {
      mockApplicationConfig({ dashboard: false })

      const router = createTestRouter()
      await router.push(path)

      expect(router.currentRoute.value.name).toBe('TicketOverview')
    },
  )
})
