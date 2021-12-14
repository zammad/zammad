// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import permissionGuard from '@common/router/guards/before/permission'
import useAuthenticatedStore from '@common/stores/authenticated'
import useSessionUserStore from '@common/stores/session/user'
import { createTestingPinia } from '@pinia/testing'
import { RouteLocationNormalized } from 'vue-router'

jest.mock('@common/server/apollo/client', () => {
  return {}
})

const errorRedirect = (route: string) => {
  return {
    name: 'Error',
    params: {
      title: 'Forbidden',
      message: "You don't have the necessary permissions to access this page.",
      statusCode: 403,
      route,
    },
    replace: true,
  }
}

describe('permissionGuard', () => {
  createTestingPinia()

  const from = {} as RouteLocationNormalized

  it('should skip guard for not authenticated user', () => {
    const to = {
      name: 'Test',
      path: '/test',
      meta: {},
    } as RouteLocationNormalized
    const next = jest.fn()

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
    const next = jest.fn()

    useAuthenticatedStore().value = true

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
    const next = jest.fn()

    useAuthenticatedStore().value = true
    useSessionUserStore().value = {
      permissions: {
        names: ['example.view'],
      },
      objectAttributeValues: [],
    }

    permissionGuard(to, from, next)

    expect(next).toHaveBeenCalledWith(errorRedirect('/tickets'))
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
    const next = jest.fn()

    useAuthenticatedStore().value = true
    useSessionUserStore().value = {
      permissions: {
        names: ['ticket.agent'],
      },
      objectAttributeValues: [],
    }

    permissionGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })
})
