// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { mockPermissions } from '@tests/support/mock-permissions'
import { useTicketCreate } from '../useTicketCreate'

describe('useTicketCreate', () => {
  it('check for agent permission and setting customer ticket create enabled', () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({
      customer_ticket_create: true,
    })

    const { ticketCreateEnabled } = useTicketCreate()

    expect(ticketCreateEnabled.value).toBe(true)
  })

  it('check for agent permission and setting customer ticket create disabled', () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({
      customer_ticket_create: true,
    })

    const { ticketCreateEnabled } = useTicketCreate()

    expect(ticketCreateEnabled.value).toBe(true)
  })

  it('check for customer permission and setting customer ticket create enabled', () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({
      customer_ticket_create: true,
    })

    const { ticketCreateEnabled } = useTicketCreate()

    expect(ticketCreateEnabled.value).toBe(true)
  })

  it('check for customer permission and setting customer ticket create disabled', () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({
      customer_ticket_create: false,
    })

    const { ticketCreateEnabled } = useTicketCreate()

    expect(ticketCreateEnabled.value).toBe(false)
  })
})
