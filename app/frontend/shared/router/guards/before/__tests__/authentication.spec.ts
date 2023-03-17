// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'
import type { RouteLocationNormalized } from 'vue-router'
import { useAuthenticationStore } from '@shared/stores/authentication'
import { useApplicationStore } from '@shared/stores/application'
import authenticationGuard from '../authentication'

vi.mock('@shared/server/apollo/client', () => {
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
    const next = vi.fn()

    authenticationGuard(to, from, next)

    expect(next).toHaveBeenCalledWith({
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
    const next = vi.fn()

    authenticationGuard(to, from, next)

    expect(next).toHaveBeenCalledWith({
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
    const next = vi.fn()

    useAuthenticationStore().authenticated = true

    authenticationGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })

  it('should redirect login route to main route for already authenticated user', () => {
    const to = {
      name: 'Login',
      path: '/login',
      meta: {
        requiresAuth: true,
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    useAuthenticationStore().authenticated = true

    authenticationGuard(to, from, next)

    expect(next).toHaveBeenCalledWith('/')
  })

  it('should give access, because requires no authentication', () => {
    const to = {
      name: 'Public',
      path: '/public',
      meta: {
        requiresAuth: false,
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    authenticationGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })
})
