// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

describe('ticket create hint note', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  it('shows the article-type note when ui_ticket_create_notes is configured for the selected type', async () => {
    mockApplicationConfig({
      ui_task_mananger_max_task_count: 30,
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      ui_ticket_create_notes: {
        'phone-in': 'Please fill in the call details carefully.',
      },
    })

    const view = await visitView('/ticket/create')

    await view.findByRole('tab', { selected: true, name: 'Received call' })

    expect(await view.findByText('Please fill in the call details carefully.')).toBeVisible()
  })

  it('does not show a note when ui_ticket_create_notes has no entry for the selected type', async () => {
    mockApplicationConfig({
      ui_task_mananger_max_task_count: 30,
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      ui_ticket_create_notes: {
        'email-out': 'Email-only note.',
      },
    })

    const view = await visitView('/ticket/create')

    await view.findByRole('tab', { selected: true, name: 'Received call' })

    expect(view.queryByText('Email-only note.')).not.toBeInTheDocument()
  })

  it('updates the article-type note when switching sender type', async () => {
    mockApplicationConfig({
      ui_task_mananger_max_task_count: 30,
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      ui_ticket_create_notes: {
        'phone-out': 'Note for outbound call.',
      },
    })

    const view = await visitView('/ticket/create')

    await view.findByRole('tab', { selected: true, name: 'Received call' })

    // Default type (phone-in) has no note — nothing visible yet.
    expect(view.queryByText('Note for outbound call.')).not.toBeInTheDocument()

    await view.events.click(await view.findByText('Outbound call'))

    expect(await view.findByText('Note for outbound call.')).toBeVisible()
  })
})
