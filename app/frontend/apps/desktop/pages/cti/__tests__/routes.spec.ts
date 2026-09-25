// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

import ctiRoutes from '../routes.ts'

// Keep the real paths, names and meta, but not the view: this is about where
//   the URL lands and what the navigation reads, not what the page renders.
const withStubbedViews = (routes: RouteRecordRaw[]): RouteRecordRaw[] =>
  routes.map((route) => ({
    ...route,
    ...('component' in route && { component: { template: '<div />' } }),
  })) as RouteRecordRaw[]

describe('caller log route', () => {
  const router = createRouter({
    history: createWebHistory('/desktop'),
    routes: withStubbedViews(ctiRoutes),
  })

  beforeEach(async () => {
    await router.push('/cti')
  })

  it('opens the caller log', () => {
    expect(router.currentRoute.value.name).toBe('CallerLog')
  })

  // The old interface's "Phone" item: permission-gated, last in the navigation,
  //   with its own entry carrying the counter and the switch.
  it('is a main navigation entry of its own', () => {
    const { meta } = router.currentRoute.value

    expect(meta.requiredPermission).toEqual(['cti.agent'])
    expect(meta.mainNavigation).toBe(true)
    expect(meta.order).toBeGreaterThan(300)
    expect(meta.navigationItemComponent).toBeDefined()
  })

  // The page itself explains a missing backend; the entry hides itself instead.
  it('keeps the page reachable without a backend', () => {
    expect(router.currentRoute.value.meta.canAccess).toBeUndefined()
  })
})
