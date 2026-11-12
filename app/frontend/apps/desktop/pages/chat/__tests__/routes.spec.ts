// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import chatRoutes from '../routes.ts'

// The session route's guard opens the window through the store; what the window list then does
//   with the id is covered with the store.
const mockOpenWindow = vi.hoisted(() => vi.fn())

vi.mock('#desktop/entities/chat/stores/chatWindows.ts', () => ({
  useChatWindowsStore: () => ({ openWindow: mockOpenWindow }),
}))

// Keep the real paths, names and meta, but not the view: this is about where
//   the URL lands and what the navigation reads, not what the page renders.
const withStubbedViews = (routes: RouteRecordRaw[]): RouteRecordRaw[] =>
  routes.map((route) => ({
    ...route,
    ...('component' in route && { component: { template: '<div />' } }),
  })) as RouteRecordRaw[]

describe('chat session route', () => {
  const router = createRouter({
    history: createWebHistory('/desktop'),
    routes: [
      ...withStubbedViews(chatRoutes),
      // Where a path no route takes lands, as in the real router.
      { path: '/:pathMatch(.*)*', name: 'Error', component: { template: '<div />' } },
    ],
  })

  beforeEach(() => {
    mockOpenWindow.mockClear()
  })

  // The old interface's session link: the window opens, the address bar shows the page.
  it('opens the window of the session and lands on the chat page', async () => {
    await router.push('/chat/session/12')

    expect(mockOpenWindow).toHaveBeenCalledWith(convertToGraphQLId('Chat::Session', 12))
    expect(router.currentRoute.value.name).toBe('Chat')
    expect(router.currentRoute.value.path).toBe('/chat')
  })

  // The addresses of the old UI, which a link from there or the switch to this view brings along.
  it('takes the session link of the old UI as well', async () => {
    await router.push('/customer_chat/session/12')

    expect(mockOpenWindow).toHaveBeenCalledWith(convertToGraphQLId('Chat::Session', 12))
    expect(router.currentRoute.value.name).toBe('Chat')
    expect(router.currentRoute.value.path).toBe('/chat')
  })

  it('takes the chat page of the old UI as well', async () => {
    await router.push('/customer_chat')

    expect(router.currentRoute.value.name).toBe('Chat')
  })

  // Back leads to where the agent chose the result, not to the page before that.
  it('keeps the page the agent came from in the history', async () => {
    await router.push('/tickets/1')
    await router.push('/chat/session/12')

    expect(window.history.state.back).toBe('/tickets/1')
  })

  it('is for chat agents only', () => {
    const route = router.getRoutes().find(({ name }) => name === 'ChatSession')

    expect(route?.meta.requiredPermission).toEqual(['chat.agent'])
    expect(route?.meta.requiresAuth).toBe(true)
  })

  it('takes no session number that is not a number', async () => {
    await router.push('/chat/session/twelve')

    expect(mockOpenWindow).not.toHaveBeenCalled()
    expect(router.currentRoute.value.name).toBe('Error')
  })
})

describe('chat route', () => {
  const router = createRouter({
    history: createWebHistory('/desktop'),
    routes: withStubbedViews(chatRoutes),
  })

  beforeEach(async () => {
    await router.push('/chat')
  })

  it('opens the chat page', () => {
    expect(router.currentRoute.value.name).toBe('Chat')
  })

  // The old interface's "Customer Chat" item: permission-gated, before the phone
  //   entry, with its own entry carrying the counter and the switch.
  it('is a main navigation entry of its own', () => {
    const { meta } = router.currentRoute.value

    expect(meta.requiredPermission).toEqual(['chat.agent'])
    expect(meta.mainNavigation).toBe(true)
    expect(meta.order).toBeGreaterThan(300)
    expect(meta.order).toBeLessThan(400)
    expect(meta.navigationItemComponent).toBeDefined()
  })

  // The page keeps its windows while the agent works elsewhere.
  it('is kept alive as a permanent page', () => {
    expect(router.currentRoute.value.meta.permanentItem).toBe(true)
  })

  // The page itself explains a disabled feature; the entry hides itself instead.
  it('keeps the page reachable while the feature is off', () => {
    expect(router.currentRoute.value.meta.canAccess).toBeUndefined()
  })
})
