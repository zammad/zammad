// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { waitForMentionSubscribeMutationCalls } from '#shared/entities/ticket/graphql/mutations/subscribe.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { getTicketUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'Adam',
      lastname: 'Doe',
    })

    mockPermissions(['ticket.agent'])
  })

  describe('Subscribers', () => {
    it('shows subscriber information', async () => {
      const ticket = createDummyTicket({
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

      mockTicketQuery({
        ticket,
      })

      mockLinkListQuery({
        linkList: [],
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Users',
                },
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
                {
                  value: 2,
                  label: 'open',
                },
                {
                  value: 6,
                  label: 'pending close',
                },
                {
                  value: 3,
                  label: 'pending reminder',
                },
              ],
            },
            pending_time: {
              show: false,
            },
            priority_id: {
              options: [
                {
                  value: 1,
                  label: '1 low',
                },
                {
                  value: 2,
                  label: '2 normal',
                },
                {
                  value: 3,
                  label: '3 high',
                },
              ],
            },
          },
          flags: {
            newArticlePresent: false,
          },
        },
      })

      const view = await visitView('/tickets/1')

      const ticketMetaSidebar = within(view.getByLabelText('Content sidebar'))

      const subscribers = ticketMetaSidebar.getByText('Subscribers')

      expect(subscribers).toBeInTheDocument()

      expect(
        ticketMetaSidebar.queryByLabelText('Avatar (Adam Doe)'),
      ).not.toBeInTheDocument()

      const toggle = view.getByLabelText('Subscribe me')
      expect(toggle).toBeInTheDocument()

      await view.events.click(toggle)

      await waitForMentionSubscribeMutationCalls()

      await getTicketUpdatesSubscriptionHandler().trigger({
        ticketUpdates: {
          ticket: {
            ...ticket,
            mentions: {
              ...ticket.mentions,
              edges: [
                ...ticket.mentions!.edges,
                {
                  cursor: 'AD',
                  node: {
                    __typename: 'Mention',
                    user: {
                      __typename: 'User',
                      id: convertToGraphQLId('User', 4),
                      internalId: 4,
                      firstname: 'Adam',
                      lastname: 'Doe',
                      fullname: 'Adam Doe',
                      active: true,
                    },
                    userTicketAccess: {
                      agentReadAccess: true,
                    },
                  },
                },
              ],
            },
          },
        },
      })

      await waitForNextTick()

      expect(
        ticketMetaSidebar.getByLabelText('Avatar (Adam Doe)'),
      ).toBeInTheDocument()
    })
  })
})
