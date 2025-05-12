// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { waitForTicketUpdateMutationCalls } from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view - draft handling', () => {
  describe('when user is an agent', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent'])

      mockLinkListQuery({
        linkList: [],
      })
    })

    it('shows save as draft if it is enabled for group and user is agent', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {},
          flags: {
            hasSharedDraft: true,
          },
        },
      })

      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const view = await visitView('/tickets/1')

      const actionMenu = await view.findByLabelText(
        'Additional ticket edit actions',
      )

      await view.events.click(actionMenu)

      const menu = await view.findByRole('menu')

      expect(within(menu).getByText('Save as draft')).toBeInTheDocument()
    })

    it('allows to apply a draft and submits draft ID to the update mutation', async () => {
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
            hasSharedDraft: true,
          },
        },
      })

      mockTicketQuery({ ticket: createDummyTicket({ sharedDraftZoomId: 123 }) })

      const view = await visitView('/tickets/1')

      const bottomButton = await view.findByRole('button', {
        name: 'Draft Available',
      })

      await view.events.click(bottomButton)

      mockFormUpdaterQuery({
        formUpdater: {
          fields: { shared_draft_id: { value: 123 } },
          flags: {
            hasSharedDraft: true,
          },
        },
      })

      const flyoutButton = await view.findByRole('button', { name: 'Apply' })

      await view.events.click(flyoutButton)

      const updateButton = await view.findByRole('button', { name: 'Update' })

      await view.events.click(updateButton)

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls?.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            sharedDraftId: convertToGraphQLId('Ticket::SharedDraftZoom', 123),
          }),
          ticketId: convertToGraphQLId('Ticket', 1),
        }),
      )
    })
  })

  describe('when user is an customer', () => {
    beforeEach(() => {
      mockPermissions(['ticket.customer'])
    })

    it('shows no save as draft if it an customer', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {},
          flags: {
            hasSharedDraft: true,
          },
        },
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          defaultPolicy: { update: true, agentReadAccess: false },
        }),
      })

      const view = await visitView('/tickets/1')

      expect(
        view.queryByLabelText('Additional ticket edit actions'),
      ).not.toBeInTheDocument()
    })
  })
})
