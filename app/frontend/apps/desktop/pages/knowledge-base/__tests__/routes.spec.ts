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

// The create view is a top-level record on purpose (it brings its own taskbar tab layout), so
//   its path has to stay clear of the section's own children and of the legacy shapes above.
describe('knowledge base answer create route', () => {
  const router = createRouter({
    history: createWebHistory('/desktop'),
    routes: withStubbedViews(knowledgeBaseRoutes),
  })

  it('matches the create route with a locale and a tab id', async () => {
    await router.push('/knowledge-base/locale/en-us/answer/create/f0a1')

    expect(router.currentRoute.value.name).toBe('KnowledgeBaseAnswerCreate')
    expect(router.currentRoute.value.params).toEqual({ localeCode: 'en-us', tabId: 'f0a1' })
  })

  // Without a tab id there is no draft to store anything under; the view's entry guard mints one.
  it('matches the create route without a tab id', async () => {
    await router.push('/knowledge-base/locale/en-us/answer/create')

    expect(router.currentRoute.value.name).toBe('KnowledgeBaseAnswerCreate')
    expect(router.currentRoute.value.params.tabId).toBeUndefined()
  })

  // Creating is editorial, and an inactive knowledge base has nothing to create in.
  it('is gated by the editor permission and the section access', async () => {
    await router.push('/knowledge-base/locale/en-us/answer/create/f0a1')

    const { meta } = router.currentRoute.value

    expect(meta.requiredPermission).toEqual(['knowledge_base.editor'])
    expect(meta.canAccess).toBeTypeOf('function')
  })

  // The create path shares its first segments with the section's own children, so each of them
  //   has to keep resolving to its own page - the `(\d+)` constraint is what keeps `create` out
  //   of the answer route.
  it.each([
    ['/knowledge-base/locale/en-us', 'KnowledgeBaseBrowse'],
    ['/knowledge-base/locale/en-us/category/2', 'KnowledgeBaseCategory'],
    ['/knowledge-base/locale/en-us/answer/3', 'KnowledgeBaseAnswer'],
  ])('leaves %s on %s', async (path, expectedName) => {
    await router.push(path)

    expect(router.currentRoute.value.name).toBe(expectedName)
  })
})
