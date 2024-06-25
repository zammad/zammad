// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

describe('testing tickets create a11y view', async () => {
  beforeEach(() => {
    mockApplicationConfig({
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
    })
    mockUserCurrent({
      permissions: { names: ['ticket.agent', 'ticket.customer'] },
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/tickets/create')

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()

    await view.events.click(view.getByRole('tab', { name: 'Send Email' }))

    expect(results).toHaveNoViolations()
  })
})
