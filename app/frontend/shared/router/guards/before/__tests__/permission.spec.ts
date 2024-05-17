// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'

import { errorOptions } from '#shared/router/error.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import permissionGuard from '../permission.ts'

import type { RouteLocationNormalized } from 'vue-router'

vi.mock('#shared/server/apollo/client.ts', () => {
  return {}
})

describe('permissionGuard', () => {
  setActivePinia(createPinia())

  const from = {} as RouteLocationNormalized

  it('should skip guard for not authenticated user', () => {
    const to = {
      name: 'Test',
      path: '/test',
      meta: {},
    } as RouteLocationNormalized
    const next = vi.fn()

    permissionGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })

  it('should skip guard for no required permission', () => {
    const to = {
      name: 'Test',
      path: '/test',
      meta: {
        requiresAuth: true,
        requiredPermission: null,
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    useAuthenticationStore().authenticated = true

    permissionGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })

  it('should forbid access for user without required permission (redirect error page)', () => {
    const to = {
      name: 'TicketOverview',
      path: '/tickets',
      fullPath: '/tickets',
      meta: {
        requiresAuth: true,
        requiredPermission: ['ticket.agent'],
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    useAuthenticationStore().authenticated = true
    useSessionStore().user = {
      id: '123',
      internalId: 1,
      permissions: {
        names: ['example.view'],
      },
      objectAttributeValues: [],
    }

    permissionGuard(to, from, next)

    expect(next).toHaveBeenCalledWith({
      name: 'Error',
      query: {
        redirect: '1',
      },
      replace: true,
    })

    expect(errorOptions.value).toEqual({
      title: 'Forbidden',
      message: "You don't have the necessary permissions to access this page.",
      statusCode: 403,
      route: '/tickets',
    })
  })

  it('should allow access for user with required permission', () => {
    const to = {
      name: 'TicketOverview',
      path: '/tickets',
      fullPath: '/tickets',
      meta: {
        requiresAuth: true,
        requiredPermission: ['ticket.agent'],
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    useAuthenticationStore().authenticated = true
    useSessionStore().user = {
      id: '123',
      internalId: 1,
      permissions: {
        names: ['ticket.agent'],
      },
      objectAttributeValues: [],
    }

    permissionGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })
})
