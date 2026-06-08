// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { flushPromises } from '@vue/test-utils'

import type { ExtendedRenderResult } from '#tests/support/components/index.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import '#tests/graphql/builders/mocks.ts'
import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'

describe('ticket create hint note', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  const nextStep = async (view: ExtendedRenderResult) => {
    await view.events.click(view.getByRole('button', { name: 'Continue' }))
  }

  const visitTicketCreate = async (path = '/tickets/create') => {
    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: {
            show: true,
            options: [
              {
                label: 'Users',
                value: 1,
              },
            ],
            clearable: true,
          },
          owner_id: {
            show: true,
            options: [{ value: 100, label: 'Max Mustermann' }],
          },
          priority_id: {
            show: true,
            options: [
              { value: 1, label: '1 low' },
              { value: 2, label: '2 normal' },
              { value: 3, label: '3 high' },
            ],
            clearable: true,
          },
          pending_time: {
            show: false,
            required: false,
            hidden: false,
            disabled: false,
          },
          state_id: {
            show: true,
            options: [
              { value: 4, label: 'closed' },
              { value: 2, label: 'open' },
              { value: 7, label: 'pending close' },
              { value: 3, label: 'pending reminder' },
            ],
            clearable: true,
          },
        },
      },
    })

    const view = await visitView(path, { mockApollo: false })

    await flushPromises()
    await getNode('ticket-create')?.settled

    return view
  }

  it('shows the article-type note when ui_ticket_create_notes is configured for the selected type', async () => {
    mockApplicationConfig({
      ui_task_mananger_max_task_count: 30,
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      ui_ticket_create_notes: {
        'phone-in': 'Please fill in the call details carefully.',
      },
    })

    const view = await visitTicketCreate()
    await flushPromises()
    await getNode('ticket-create')?.settled

    await view.events.type(await view.findByLabelText('Title'), 'Foobar')
    await waitForFormUpdaterQueryCalls()
    await nextStep(view)

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

    const view = await visitTicketCreate()

    await view.events.click(await view.findByText('Received call'))

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

    const view = await visitTicketCreate()

    await view.findByText('Received call')

    // Default type (phone-in) has no note — nothing visible yet.
    expect(view.queryByText('Note for outbound call.')).not.toBeInTheDocument()

    await view.events.click(await view.findByText('Outbound call'))

    expect(await view.findByText('Note for outbound call.')).toBeInTheDocument()
  })
})
