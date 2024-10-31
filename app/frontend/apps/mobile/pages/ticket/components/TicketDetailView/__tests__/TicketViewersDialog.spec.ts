// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTaskbarApp } from '#shared/graphql/types.ts'

import TicketViewersDialog from '../TicketViewersDialog.vue'

describe('displaying ticket viewer dialog', () => {
  it('displays some "live" viewer and "idle" viewer', () => {
    const view = renderComponent(TicketViewersDialog, {
      props: {
        name: 'ticket-viewers-dialog',
        liveUsers: [
          {
            user: {
              id: '654321',
              firstname: 'John',
              lastname: 'Doe',
              fullname: 'John Doe',
            },
            app: EnumTaskbarApp.Desktop,
            lastInteraction: new Date().toISOString(),
            editing: false,
          },
          {
            user: {
              id: '123123',
              firstname: 'Rose',
              lastname: 'Nylund',
              fullname: 'Rose Nylund',
            },
            app: EnumTaskbarApp.Desktop,
            lastInteraction: new Date().toISOString(),
            editing: false,
          },
          {
            user: {
              id: '524523',
              firstname: 'Sophia',
              lastname: 'Petrillo',
              fullname: 'Sophia Petrillo',
            },
            app: EnumTaskbarApp.Mobile,
            lastInteraction: new Date('2019-01-01 00:00:00').toISOString(),
            editing: false,
          },
        ],
      },
      router: true,
    })

    expect(view.getByText('Viewing ticket')).toBeInTheDocument()
    expect(view.getByText('Opened in tabs')).toBeInTheDocument()
  })
})
