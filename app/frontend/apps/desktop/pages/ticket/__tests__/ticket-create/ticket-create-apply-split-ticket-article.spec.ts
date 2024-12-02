// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { waitForFormUpdaterQueryCalls } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { waitForTicketCreateMutationCalls } from '#shared/entities/ticket/graphql/mutations/create.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { handleMockFormUpdaterQuery } from '#desktop/pages/ticket/__tests__/support/ticket-create-helpers.ts'

describe('ticket create view - splitting of a ticket article', async () => {
  const ticketTitle = 'split title'
  const articleId = 666
  const ticketId = 123

  beforeEach(() => {
    mockApplicationConfig({
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
    })
    mockPermissions(['ticket.agent'])
    handleMockFormUpdaterQuery()
  })

  it('applies given ticket article', async () => {
    handleMockFormUpdaterQuery({
      title: { value: ticketTitle },
      split_article_id: articleId,
    })

    const view = await visitView(
      '/ticket/create?splitTicketArticleId=ticket_article_gid',
    )

    const formUpdaterCalls = await waitForFormUpdaterQueryCalls()

    expect(formUpdaterCalls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        meta: expect.objectContaining({
          additionalData: expect.objectContaining({
            splitTicketArticleId: 'ticket_article_gid',
          }),
        }),
      }),
    )

    await waitForNextTick()

    expect(view.getByLabelText('Title')).toHaveValue(ticketTitle)
  })

  it('submits linking when creating', async () => {
    handleMockFormUpdaterQuery({
      title: { value: ticketTitle },
      body: { value: 'body' },
      group_id: {
        value: 1,
        options: [
          {
            value: 1,
            label: 'Users',
          },
          {
            value: 2,
            label: 'some group1',
          },
        ],
      },
      customer_id: { value: 1 },
      link_ticket_id: { value: ticketId },
      pending_time: { show: false },
    })

    const view = await visitView(
      '/ticket/create?splitTicketArticleId=ticket_article_gid',
    )

    await waitForFormUpdaterQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Create' }))

    const ticketCreateCalls = await waitForTicketCreateMutationCalls()
    expect(ticketCreateCalls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        input: expect.objectContaining({
          title: ticketTitle,
          links: [
            {
              linkType: 'child',
              linkObjectId: convertToGraphQLId('Ticket', ticketId),
            },
          ],
        }),
      }),
    )
  })
})
