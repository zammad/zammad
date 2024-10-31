// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketSubscribers, {
  type Props,
} from '../TicketSidebarInformationContent/TicketSubscribers.vue'

const provideTestTicket = (subscribed: boolean = false) => {
  return createDummyTicket({
    subscribed,
    mentions: {
      __typename: 'MentionConnection',
      totalCount: 3,
      edges: [
        {
          cursor: 'AA',
          node: {
            __typename: 'Mention',
            user: {
              __typename: 'User',
              id: convertToGraphQLId('User', 1),
              internalId: 1,
              firstname: 'John',
              lastname: 'Doe',
              fullname: 'John Doe',
              active: true,
            },
            userTicketAccess: {
              agentReadAccess: true,
            },
          },
        },
        {
          cursor: 'AB',
          node: {
            __typename: 'Mention',
            user: {
              __typename: 'User',
              id: convertToGraphQLId('User', 2),
              internalId: 2,
              firstname: 'Jane',
              lastname: 'Doe',
              fullname: 'Jane Doe',
              active: true,
            },
            userTicketAccess: {
              agentReadAccess: true,
            },
          },
        },
        {
          cursor: 'AC',
          node: {
            __typename: 'Mention',
            user: {
              __typename: 'User',
              id: convertToGraphQLId('User', 3),
              internalId: 3,
              firstname: 'Jim',
              lastname: 'Doe',
              fullname: 'Jim Doe',
              active: false,
            },
            userTicketAccess: {
              agentReadAccess: true,
            },
          },
        },
      ],
    },
  })
}

const renderTicketSubscribers = (props: Partial<Props> = {}) =>
  renderComponent(TicketSubscribers, {
    props: {
      ticket: provideTestTicket(),
      ...props,
    },
    router: true,
    form: true,
  })

describe('TicketSubscribers', () => {
  it('renders a toggle to subscribe/unsubscribe', () => {
    const view = renderTicketSubscribers()

    const toggle = view.getByLabelText('Subscribe me')

    expect(toggle).toBeInTheDocument()
    expect(toggle).not.toBeChecked()
  })

  it('renders a toggle as checked if user is subscribed to ticket', () => {
    const view = renderTicketSubscribers({
      ticket: provideTestTicket(true),
    })

    const toggle = view.getByLabelText('Subscribe me')

    expect(toggle).toBeChecked()
  })

  it('renders a list of subscribers', () => {
    const view = renderTicketSubscribers()

    expect(view.getByLabelText('Avatar (John Doe)')).toBeInTheDocument()
    expect(view.getByLabelText('Avatar (Jane Doe)')).toBeInTheDocument()

    // Inactive users should not be rendered
    expect(view.queryByLabelText('Avatar (Jim Doe)')).not.toBeInTheDocument()
  })
})
