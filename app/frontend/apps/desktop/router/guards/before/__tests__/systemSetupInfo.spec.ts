// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import systemGuard from '../systemSetupInfo.ts'

import type { RouteLocationNormalized } from 'vue-router'

describe('systemGuard', () => {
  const from = {} as RouteLocationNormalized

  it('should redirect to guided-setup when system setup is not ready', () => {
    mockApplicationConfig({
      system_init_done: false,
    })

    const to = {
      name: 'Test',
      path: '/test',
      fullPath: '/test',
      meta: {},
    } as RouteLocationNormalized
    const next = vi.fn()

    systemGuard(to, from, next)

    expect(next).toHaveBeenCalledWith({
      path: '/guided-setup',
      replace: true,
    })
  })

  it('should redirect to guided-setup/import when import mode is active', () => {
    mockApplicationConfig({
      system_init_done: false,
      import_mode: true,
      import_backend: 'otrs',
    })

    const to = {
      name: 'Test',
      path: '/test',
      fullPath: '/test',
      meta: {},
    } as RouteLocationNormalized
    const next = vi.fn()

    systemGuard(to, from, next)

    expect(next).toHaveBeenCalledWith({
      path: '/guided-setup/import/otrs/status',
      replace: true,
    })
  })

  it('should do nothing, when system setup is done', () => {
    mockApplicationConfig({
      system_init_done: true,
    })

    const to = {
      name: 'Test',
      path: '/test',
      fullPath: '/test',
      meta: {},
    } as RouteLocationNormalized
    const next = vi.fn()

    systemGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })

  it('should do nothing, when guided-setup is inside the path', () => {
    mockApplicationConfig({
      system_init_done: true,
    })

    const to = {
      name: 'GuidedSetupAdminSignup',
      path: '/guided-setup/manual/admin',
      fullPath: '/guided-setup/manual/admin',
      meta: {},
    } as RouteLocationNormalized
    const next = vi.fn()

    systemGuard(to, from, next)

    expect(next).toHaveBeenCalledWith()
  })
})
