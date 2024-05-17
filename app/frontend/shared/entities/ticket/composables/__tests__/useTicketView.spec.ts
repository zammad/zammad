// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import type { Ticket } from '#shared/graphql/types.ts'

import { useTicketView } from '../useTicketView.ts'

const ticketDefault = generateObjectData<Ticket>('Ticket')
const ticket = ref<Ticket | undefined>(ticketDefault)

describe('useTicketView', () => {
  it('check agent permission', () => {
    mockPermissions([])

    const { isTicketAgent, isTicketCustomer } = useTicketView(ticket)

    expect(isTicketAgent.value).toBe(false)
    expect(isTicketCustomer.value).toBe(false)

    mockPermissions(['ticket.agent'])
    ticket.value!.policy.agentReadAccess = true

    expect(isTicketAgent.value).toBe(true)
    expect(isTicketCustomer.value).toBe(false)
  })

  it('check customer permissions', () => {
    mockPermissions(['ticket.customer'])
    ticket.value!.policy.agentReadAccess = false

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
        ...ticketDefault.policy,
        __typename: 'PolicyTicket',
        update: false,
        agentReadAccess: true,
      },
    }

    expect(isTicketEditable.value).toBe(false)

    ticket.value = undefined

    expect(isTicketEditable.value).toBe(false)
  })
})
