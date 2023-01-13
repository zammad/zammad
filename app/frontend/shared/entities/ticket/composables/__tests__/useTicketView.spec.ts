// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketById } from '@shared/entities/ticket/types'
import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { mockPermissions } from '@tests/support/mock-permissions'
import { ref } from 'vue'
import { useTicketView } from '../useTicketView'

const ticketDefault = defaultTicket().ticket
const ticket = ref<TicketById | undefined>(ticketDefault)

describe('useTicketView', () => {
  it('check agent permission', () => {
    mockPermissions([])

    const { isTicketAgent, isTicketCustomer } = useTicketView(ticket)

    expect(isTicketAgent.value).toBe(false)
    expect(isTicketCustomer.value).toBe(false)

    mockPermissions(['ticket.agent'])

    expect(isTicketAgent.value).toBe(true)
    expect(isTicketCustomer.value).toBe(false)
  })

  it('check customer permissions', () => {
    mockPermissions(['ticket.customer'])

    const { isTicketAgent, isTicketCustomer } = useTicketView(ticket)

    expect(isTicketAgent.value).toBe(false)
    expect(isTicketCustomer.value).toBe(true)
  })

  it('check ticket editable state', async () => {
    const { isTicketEditable } = useTicketView(ticket)

    expect(isTicketEditable.value).toBe(true)

    ticket.value = {
      ...ticketDefault,
      policy: {
        __typename: 'Policy',
        update: false,
      },
    }

    expect(isTicketEditable.value).toBe(false)

    ticket.value = undefined

    expect(isTicketEditable.value).toBe(false)
  })
})
