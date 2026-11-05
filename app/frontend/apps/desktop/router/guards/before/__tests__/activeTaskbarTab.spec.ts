// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumTaskbarEntity } from '#shared/graphql/types.ts'

import activeTaskbarTab from '../activeTaskbarTab.ts'

import type { RouteLocationNormalized } from 'vue-router'

const upsertTaskbarTab = vi.fn()

vi.mock('#desktop/entities/user/current/stores/taskbarTabs.ts', () => ({
  useUserCurrentTaskbarTabsStore: () => ({
    loading: false,
    getTaskbarTabTypePlugin: () => ({ buildEntityTabKey: () => 'Ticket-1' }),
    upsertTaskbarTab,
  }),
}))

describe('activeTaskbarTab', () => {
  const from = {} as RouteLocationNormalized

  const to = {
    name: 'TicketDetailView',
    path: '/tickets/1',
    fullPath: '/tickets/1',
    meta: { taskbarTabEntity: EnumTaskbarEntity.TicketZoom },
  } as unknown as RouteLocationNormalized

  it('handles a failure to store the taskbar tab and lets the navigation pass', async () => {
    const failure = Promise.reject(new TypeError('NetworkError when attempting to fetch resource.'))
    const catchSpy = vi.spyOn(failure, 'catch')

    upsertTaskbarTab.mockReturnValue(failure)

    await expect(activeTaskbarTab(to, from, vi.fn())).resolves.toBe(true)

    expect(upsertTaskbarTab).toHaveBeenCalledWith(EnumTaskbarEntity.TicketZoom, 'Ticket-1', to)
    expect(catchSpy).toHaveBeenCalled()
    expect(to.meta.taskbarTabEntityKey).toBe('Ticket-1')
  })
})
