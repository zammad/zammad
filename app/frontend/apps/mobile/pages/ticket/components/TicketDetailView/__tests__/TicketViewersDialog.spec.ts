// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { EnumTaskbarApp } from '@shared/graphql/types'
import { renderComponent } from '@tests/support/components'
import TicketViewersDialog from '../TicketViewersDialog.vue'

describe('displaying ticket viewer dialog', () => {
  it('displays the some "live" viewer and "idle" viewer', () => {
    const view = renderComponent(TicketViewersDialog, {
      props: {
        name: 'ticket-viewers-dialog',
        liveUsers: [
          {
            editing: false,
            user: { id: '654321', firstname: 'John', lastname: 'Doe' },
            lastInteraction: new Date().toISOString(),
            apps: [EnumTaskbarApp.Desktop],
          },
          {
            editing: false,
            user: { id: '123123', firstname: 'Rose', lastname: 'Nylund' },
            lastInteraction: new Date().toISOString(),
            apps: [EnumTaskbarApp.Desktop],
          },
          {
            editing: false,
            user: { id: '524523', firstname: 'Sophia', lastname: 'Petrillo' },
            lastInteraction: new Date('2019-01-01 00:00:00').toISOString(),
            apps: [EnumTaskbarApp.Mobile],
          },
        ],
      },
    })

    expect(view.getByText('Viewing ticket')).toBeInTheDocument()
    expect(view.getByText('Opened in tabs')).toBeInTheDocument()
  })
})
