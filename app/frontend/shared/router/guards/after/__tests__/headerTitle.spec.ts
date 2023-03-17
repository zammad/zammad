// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'
import type { RouteLocationNormalized } from 'vue-router'
import { nextTick } from 'vue'
import useMetaTitle from '@shared/composables/useMetaTitle'
import { useApplicationStore } from '@shared/stores/application'
import headerTitle from '../headerTitle'

describe('headerTitle', () => {
  createTestingPinia({ createSpy: vi.fn })
  useApplicationStore().config.product_name = 'Zammad'

  const from = {} as RouteLocationNormalized

  beforeEach(() => {
    useMetaTitle().initializeMetaTitle()
  })

  it('should change the header title from the route meta data', async () => {
    expect.assertions(2)
    const to = {
      name: 'TicketOverview',
      path: '/tickets',
      meta: {
        title: 'Ticket Overview',
        requiresAuth: true,
      },
    } as RouteLocationNormalized

    expect(document.title).toEqual('Zammad')

    headerTitle(to, from)

    await nextTick()

    expect(document.title).toEqual('Zammad - Ticket Overview')
  })
})
