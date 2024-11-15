// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumLinkType } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockTicketRelationAndRecentTicketListsQuery } from '#desktop/pages/ticket/graphql/queries/ticketRelationAndRecentTicketLists.mocks.ts'

import {
  mockLinkAddMutation,
  waitForLinkAddMutationCalls,
} from '../../graphql/mutations/linkAdd.mocks.ts'
import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view links', () => {
  it('opens the links flyout and adds a link', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketRelationAndRecentTicketListsQuery({
      ticketsRecentlyViewed: [createDummyTicket()],
      ticketsRecentByCustomer: [
        createDummyTicket({
          title: 'Foo Car',
          ticketId: '1111',
        }),
      ],
    })

    const ticket = createDummyTicket()

    mockTicketQuery({
      ticket,
    })

    mockLinkListQuery({
      linkList: [],
    })

    const view = await visitView('/tickets/1')

    const ticketMetaSidebar = within(view.getByLabelText('Content sidebar'))

    expect(ticketMetaSidebar.getByText('Links')).toBeInTheDocument()
    expect(
      ticketMetaSidebar.getByText('No links added yet.'),
    ).toBeInTheDocument()

    await view.events.click(
      await view.findByRole('button', { name: 'Add link' }),
    )

    expect(
      await view.findByRole('heading', { name: 'Link Tickets', level: 2 }),
    ).toBeInTheDocument()

    expect(await view.findByText('Recent Customer Tickets')).toBeInTheDocument()
    expect(view.getByText('Recently Viewed Tickets')).toBeInTheDocument()
    expect(view.getByText('Foo Car')).toBeInTheDocument()

    const rows = view.getAllByLabelText('Select table row')

    mockLinkAddMutation({
      linkAdd: {
        __typename: 'LinkAddPayload',
        link: {
          __typename: 'Link',
          item: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', '1111'),
            title: 'Foo Car',
          },
          type: EnumLinkType.Parent,
        },
      },
    })

    await view.events.click(rows[0])
    await view.events.click(view.getByRole('button', { name: 'Link' }))

    await waitForLinkAddMutationCalls()

    mockLinkListQuery({
      linkList: [
        {
          __typename: 'Link',
          item: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', '1111'),
            title: 'Foo Car',
          },
          type: EnumLinkType.Parent,
        },
      ],
    })

    await waitForNextTick()

    expect(
      ticketMetaSidebar.queryByText('No links added yet.'),
    ).not.toBeInTheDocument()

    expect(view.getByText('Parent')).toBeInTheDocument()
    expect(view.getByText('Foo Car')).toBeInTheDocument()
  })
})
