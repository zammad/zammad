// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import {
  createRouter,
  createWebHistory,
  type RouteLocationNormalized,
} from 'vue-router'

import { setCurrentRouter } from '#shared/router/router.ts'

import redirectGuard from '../redirect.ts'

vi.mock('#shared/server/apollo/client.ts', () => {
  return {}
})

describe('redirectGuard', () => {
  setActivePinia(createPinia())

  const history = createWebHistory('/')

  const routes = [
    {
      name: 'Target',
      path: '/target',
      alias: '/another-target',
      component: {
        template: 'target',
      },
    },
    {
      name: 'Error',
      path: '/error',
      alias: '/:pathMatch(.*)*',
      component: {
        template: 'error',
      },
    },
  ]

  const router = createRouter({ history, routes })

  setCurrentRouter(router)

  const from = {} as RouteLocationNormalized
  const next = vi.fn()

  it('should skip guard when already redirected', () => {
    const to = {
      name: 'Source',
      path: '/source',
      redirectedFrom: {
        path: '/previous-route',
      },
    } as RouteLocationNormalized

    const result = redirectGuard(to, from, next)

    expect(result).toBe(true)
  })

  it('should skip guard when hash is missing', () => {
    const to = {
      name: 'Source',
      path: '/source',
    } as RouteLocationNormalized

    const result = redirectGuard(to, from, next)

    expect(result).toBe(true)
  })

  it('should replace with home for an unknown path', () => {
    const to = {
      name: 'Source',
      path: '/source',
      hash: '#foobar',
    } as RouteLocationNormalized

    const result = redirectGuard(to, from, next)

    expect(result).toEqual({
      path: '/',
      replace: true,
    })
  })

  it('should replace with target for a known path', () => {
    const to = {
      name: 'Source',
      path: '/source',
      hash: '#another-target',
    } as RouteLocationNormalized

    const result = redirectGuard(to, from, next)

    expect(result).toEqual({
      path: '/another-target',
      replace: true,
    })
  })
})
