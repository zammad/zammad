// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mockPermissions } from '@tests/support/mock-permissions'
import { useTicketView } from '../useTicketView'

describe('useTicketView', () => {
  it('should be defined', () => {
    mockPermissions([])

    const { isTicketAgent } = useTicketView()

    expect(isTicketAgent.value).toBe(false)

    mockPermissions(['ticket.agent'])

    expect(isTicketAgent.value).toBe(true)
  })
})
