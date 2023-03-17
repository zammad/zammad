// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import { errorOptions } from '@mobile/router/error'
import type { RouteLocationNormalized } from 'vue-router'
import { useAuthenticationStore } from '@shared/stores/authentication'
import { useSessionStore } from '@shared/stores/session'
import permissionGuard from '../permission'

vi.mock('@shared/server/apollo/client', () => {
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
