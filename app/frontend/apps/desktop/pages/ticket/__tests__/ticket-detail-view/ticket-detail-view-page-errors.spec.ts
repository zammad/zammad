// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, expect } from 'vitest'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentTaskbarItemListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'
import { getUserCurrentTaskbarItemUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTaskbarItemUpdates.mocks.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view error handling', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })
  })

  it('shows an error page if ticket is not authorized', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 123),
          key: 'Ticket-123',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Forbidden,
          entity: null,
        },
      ],
    })

    const view = await visitView('/tickets/123')

    expect(view).toHaveCurrentUrl('/tickets/123')
    expect(view.getByRole('img', { name: 'Error' })).toBeInTheDocument()

    expect(view.getByRole('heading', { level: 1 })).toHaveTextContent(
      'Forbidden',
    )

    expect(
      view.getByText('You have insufficient rights to view this ticket.'),
    ).toBeInTheDocument()
  })

  it('shows an error page if ticket is not found', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 999),
          key: 'Ticket-999',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.NotFound,
          entity: null,
        },
      ],
    })

    const view = await visitView('/tickets/999')

    expect(view).toHaveCurrentUrl('/tickets/999')
    expect(view.getByRole('img', { name: 'Error' })).toBeInTheDocument()

    expect(view.getByRole('heading', { level: 1 })).toHaveTextContent(
      'Not Found',
    )

    expect(
      view.getByText(
        'Ticket with specified ID was not found. Try checking the URL for errors.',
      ),
    ).toBeInTheDocument()
  })

  it('automatically shows an error page when the access is lost', async () => {
    const ticket = createDummyTicket({
      ticketId: '123',
    })

    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 123),
          key: 'Ticket-123',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: ticket,
        },
      ],
    })

    mockTicketQuery({
      ticket,
    })

    const view = await visitView('/tickets/123')

    expect(view.getByRole('main')).toHaveTextContent(ticket.title)

    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        updateItem: {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 123),
          key: 'Ticket-123',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Forbidden,
          entity: null,
        },
      },
    })

    expect(view.getByRole('main')).not.toHaveTextContent(ticket.title)

    expect(
      view.getByText('You have insufficient rights to view this ticket.'),
    ).toBeInTheDocument()
  })

  it('automatically shows the ticket when the access is regained', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 123),
          key: 'Ticket-123',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Forbidden,
          entity: null,
        },
      ],
    })

    const view = await visitView('/tickets/123')

    expect(
      view.getByText('You have insufficient rights to view this ticket.'),
    ).toBeInTheDocument()

    const ticket = createDummyTicket({
      ticketId: '123',
    })

    mockTicketQuery({
      ticket,
    })

    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        updateItem: {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 123),
          key: 'Ticket-123',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: ticket,
        },
      },
    })

    expect(
      view.queryByText('You have insufficient rights to view this ticket.'),
    ).not.toBeInTheDocument()

    expect(view.getByRole('main')).toHaveTextContent(ticket.title)
  })
})
