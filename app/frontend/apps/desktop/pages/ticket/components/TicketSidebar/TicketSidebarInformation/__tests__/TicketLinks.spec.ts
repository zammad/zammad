// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumLinkType } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockLinkListQuery } from '#desktop/pages/ticket/graphql/queries/linkList.mocks.ts'
import { getLinkUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/linkUpdates.mocks.ts'

import TicketLinks, {
  type Props,
} from '../TicketSidebarInformationContent/TicketLinks.vue'

const renderTicketLinks = (props: Partial<Props> = {}) =>
  renderComponent(TicketLinks, {
    props: {
      ticket: createDummyTicket(),
      isTicketEditable: true,
      ...props,
    },
    router: true,
    form: true,
  })

describe('TicketLinks', () => {
  it('renders a hint when no links are present', async () => {
    mockLinkListQuery({
      linkList: [],
    })

    const view = renderTicketLinks()

    await waitForNextTick()

    expect(view.getByText('No links added yet.')).toBeInTheDocument()
  })

  it('renders a button to create new links', async () => {
    mockLinkListQuery({
      linkList: [],
    })

    const view = renderTicketLinks()

    await waitForNextTick()

    expect(view.getByLabelText('Add link')).toBeInTheDocument()
  })

  it('renders a list of links', async () => {
    mockLinkListQuery({
      linkList: [
        {
          item: {
            __typename: 'Ticket',
            id: 'gid://zammad/Ticket/2',
            title: 'Ticket 2',
            state: {
              __typename: 'TicketState',
              id: convertToGraphQLId('Ticket::State', 2),
              name: 'open',
            },
          },
          type: EnumLinkType.Child,
        },
        {
          item: {
            __typename: 'Ticket',
            id: 'gid://zammad/Ticket/3',
            title: 'Ticket 3',
            state: {
              __typename: 'TicketState',
              id: convertToGraphQLId('Ticket::State', 2),
              name: 'open',
            },
          },
          type: EnumLinkType.Child,
        },
        {
          item: {
            __typename: 'Ticket',
            id: 'gid://zammad/Ticket/4',
            title: 'Ticket 4',
            state: {
              __typename: 'TicketState',
              id: convertToGraphQLId('Ticket::State', 2),
              name: 'open',
            },
          },
          type: EnumLinkType.Normal,
        },
      ],
    })

    const view = renderTicketLinks()

    await waitForNextTick()

    expect(view.getByText('Child')).toBeInTheDocument()
    expect(view.getByText('Normal')).toBeInTheDocument()
    expect(view.queryByText('Parent')).not.toBeInTheDocument()

    expect(view.getByText('Ticket 2')).toBeInTheDocument()
    expect(view.getByText('Ticket 3')).toBeInTheDocument()
    expect(view.getByText('Ticket 4')).toBeInTheDocument()

    await getLinkUpdatesSubscriptionHandler().trigger({
      linkUpdates: {
        links: [],
      },
    })

    await waitForNextTick()

    expect(view.getByText('No links added yet.')).toBeInTheDocument()

    await getLinkUpdatesSubscriptionHandler().trigger({
      linkUpdates: {
        links: [
          {
            item: {
              __typename: 'Ticket',
              id: 'gid://zammad/Ticket/5',
              title: 'Ticket 5',
              state: {
                __typename: 'TicketState',
                id: convertToGraphQLId('Ticket::State', 2),
                name: 'open',
              },
            },
            type: EnumLinkType.Parent,
          },
        ],
      },
    })

    await waitForNextTick()

    expect(view.queryByText('Child')).not.toBeInTheDocument()
    expect(view.queryByText('Normal')).not.toBeInTheDocument()
    expect(view.getByText('Parent')).toBeInTheDocument()

    expect(view.getByText('Ticket 5')).toBeInTheDocument()
  })
})
