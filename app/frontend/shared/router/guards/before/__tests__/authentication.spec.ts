// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import authenticationGuard from '../authentication.ts'

import type { RouteLocationNormalized } from 'vue-router'

vi.mock('#shared/server/apollo/client.ts', () => {
  return {}
})

describe('authenticationGuard', () => {
  createTestingPinia({ createSpy: vi.fn })
  useApplicationStore().loaded = true

  const from = {} as RouteLocationNormalized

  it('should redirect not authenticated user to login', () => {
    const to = {
      name: 'TicketOverview',
      path: '/tickets',
      fullPath: '/tickets',
      meta: {
        requiresAuth: true,
      },
    } as RouteLocationNormalized

    useAuthenticationStore().authenticated = false

    const result = authenticationGuard(to, from, vi.fn())

    expect(result).toEqual({
      path: '/login',
      query: {
        redirect: '/tickets',
      },
    })
  })

  it('should redirect not authenticated user to login (without a redirect path)', () => {
    const to = {
      name: 'Home',
      path: '/',
      fullPath: '/',
      meta: {
        requiresAuth: true,
      },
    } as RouteLocationNormalized

    useAuthenticationStore().authenticated = false

    const result = authenticationGuard(to, from, vi.fn())

    expect(result).toEqual({
      path: '/login',
    })
  })

  it('should give access to route for authenticated user', () => {
    const to = {
      name: 'TicketOverview',
      path: '/tickets',
      meta: {
        requiresAuth: true,
      },
    } as RouteLocationNormalized

    useAuthenticationStore().authenticated = true

    const result = authenticationGuard(to, from, vi.fn())

    expect(result).toBe(true)
  })

  it('should redirect login route to main route for already authenticated user', () => {
    const to = {
      name: 'Login',
      path: '/login',
      meta: {
        requiresAuth: true,
        redirectToDefaultRoute: true,
      },
    } as RouteLocationNormalized

    useAuthenticationStore().authenticated = true

    const result = authenticationGuard(to, from, vi.fn())

    expect(result).toBe('/')
  })

  it('should give access, because requires no authentication', () => {
    const to = {
      name: 'Public',
      path: '/public',
      meta: {
        requiresAuth: false,
      },
    } as RouteLocationNormalized

    useAuthenticationStore().authenticated = false

    const result = authenticationGuard(to, from, vi.fn())

    expect(result).toBe(true)
  })
})
