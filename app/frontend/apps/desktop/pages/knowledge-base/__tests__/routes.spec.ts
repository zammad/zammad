// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

import knowledgeBaseRoutes from '../routes.ts'

// Keep the real paths, names and redirects, but not the views: their entry guards need the
//   whole app (store, apollo), and this is about where a URL lands, not what it renders.
const withStubbedViews = (routes: RouteRecordRaw[]): RouteRecordRaw[] =>
  routes.map((route) => ({
    ...route,
    ...('component' in route && { component: { template: '<div />' } }),
    ...(route.children && { children: withStubbedViews(route.children) }),
  })) as RouteRecordRaw[]

// The legacy stack's knowledge base URLs still arrive here (answer bodies, the public help
//   site's "edit" button, links copied out of the old interface — including from the feeds),
//   so every shape it produces has to land on the matching page of the new interface.
describe('knowledge base legacy URLs', () => {
  const router = createRouter({
    history: createWebHistory('/desktop'),
    routes: withStubbedViews(knowledgeBaseRoutes),
  })

  it.each([
    ['/knowledge_base/1/locale/en-us', '/knowledge-base/locale/en-us'],
    ['/knowledge_base/1/locale/en-us/edit', '/knowledge-base/locale/en-us'],
    ['/knowledge_base/1/locale/en-us/category/2', '/knowledge-base/locale/en-us/category/2'],
    ['/knowledge_base/1/locale/en-us/category/2/edit', '/knowledge-base/locale/en-us/category/2'],
    ['/knowledge_base/1/locale/en-us/answer/3', '/knowledge-base/locale/en-us/answer/3'],
    ['/knowledge_base/1/locale/en-us/answer/3/edit', '/knowledge-base/locale/en-us/answer/3'],
  ])('opens %s at %s', async (legacyPath, expectedPath) => {
    await router.push(legacyPath)

    expect(router.currentRoute.value.path).toBe(expectedPath)
  })
})
