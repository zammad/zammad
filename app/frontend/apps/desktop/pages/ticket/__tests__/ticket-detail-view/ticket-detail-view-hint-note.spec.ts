// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

describe('article reply hint note', () => {
  const makeFormUpdaterOptions = () => ({
    formUpdater: {
      fields: {
        group_id: {
          options: [
            { value: 1, label: 'Users' },
            { value: 2, label: 'test group' },
          ],
        },
        owner_id: { options: [{ value: 3, label: 'Test Admin Agent' }] },
        state_id: {
          options: [
            { value: 4, label: 'closed' },
            { value: 2, label: 'open' },
            { value: 6, label: 'pending close' },
            { value: 3, label: 'pending reminder' },
          ],
        },
        pending_time: { show: false },
        priority_id: {
          options: [
            { value: 1, label: '1 low' },
            { value: 2, label: '2 normal' },
            { value: 3, label: '3 high' },
          ],
        },
      },
      flags: { newArticlePresent: false },
    },
  })

  const openInternalNoteReply = async () => {
    mockTicketQuery({
      ticket: createDummyTicket({
        defaultPolicy: { update: true, agentReadAccess: true },
      }),
    })
    mockFormUpdaterQuery(makeFormUpdaterOptions())

    const view = await visitView('/tickets/1')
    await waitForFormUpdaterQueryCalls()
    await view.events.click(await view.findByRole('button', { name: 'Add internal note' }))
    const complementary = await view.findByRole('complementary', { name: 'Reply' })
    await getNode('form-ticket-edit-1')?.settled
    return { view, complementary }
  }

  it('shows the hint note when ui_ticket_add_article_hint is configured for the current article type and visibility', async () => {
    mockApplicationConfig({
      ui_ticket_zoom_article_note_new_internal: true,
      ui_ticket_add_article_hint: {
        'note-internal': 'Please keep internal notes concise.',
      },
    })

    const { complementary } = await openInternalNoteReply()

    // Reply form defaults to Internal — hint should be visible.
    expect(
      await within(complementary).findByText('Please keep internal notes concise.'),
    ).toBeVisible()
  })

  it('does not show the hint note when ui_ticket_add_article_hint has no entry for the current type and visibility', async () => {
    mockApplicationConfig({
      ui_ticket_zoom_article_note_new_internal: true,
      ui_ticket_add_article_hint: {
        'note-public': 'Public note hint.',
      },
    })

    const { complementary } = await openInternalNoteReply()

    expect(within(complementary).queryByText('Public note hint.')).not.toBeInTheDocument()
  })

  it('updates the hint note when visibility is changed', async () => {
    mockApplicationConfig({
      ui_ticket_zoom_article_note_new_internal: true,
      ui_ticket_add_article_hint: {
        'note-public': 'Public note hint.',
      },
    })

    const { view, complementary } = await openInternalNoteReply()

    expect(within(complementary).queryByText('Public note hint.')).not.toBeInTheDocument()

    await view.events.click(within(complementary).getByLabelText('Visibility'))
    await view.events.click(await view.findByRole('option', { name: 'Public' }))
    await getNode('form-ticket-edit-1')?.settled

    expect(await within(complementary).findByText('Public note hint.')).toBeVisible()
  })
})
