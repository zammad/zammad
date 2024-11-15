// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { within } from '@testing-library/vue'
import { expect } from 'vitest'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  mockTicketUpdateMutation,
  waitForTicketUpdateMutationCalls,
} from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { getTicketUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumUserErrorException } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockChecklistTemplatesQuery } from '#desktop/pages/ticket/graphql/queries/checklistTemplates.mocks.ts'
import { mockTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.mocks.ts'
import { getTicketChecklistUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketChecklistUpdates.mocks.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })
  })

  describe('Checklist', () => {
    it('shows checklist if it is enabled and user is agent', async () => {
      mockApplicationConfig({ checklist: true })

      mockTicketChecklistQuery({
        ticketChecklist: null,
      })

      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const view = await visitView('/tickets/1')
      await view.events.click(view.getByLabelText('Checklist'))

      expect(
        view.getByRole('heading', { name: 'Checklist', level: 2 }),
      ).toBeInTheDocument()
    })

    it('hides checklist if it is disabled and user is agent', async () => {
      mockApplicationConfig({ checklist: false })

      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const view = await visitView('/tickets/1')

      expect(
        view.queryByRole('heading', { name: 'Checklist', level: 2 }),
      ).not.toBeInTheDocument()
    })

    it('hides checklist if it is enabled and user is customer', async () => {
      mockPermissions(['ticket.customer'])

      mockApplicationConfig({ checklist: true })

      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const view = await visitView('/tickets/1')

      expect(
        view.queryByRole('heading', { name: 'Checklist', level: 2 }),
      ).not.toBeInTheDocument()
    })

    it('shows checklist ticket link for readonly agent', async () => {
      mockApplicationConfig({ checklist: true })

      const ticket = createDummyTicket()

      mockTicketQuery({
        ticket,
      })

      mockChecklistTemplatesQuery({
        checklistTemplates: null,
      })

      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          completed: false,
          incomplete: 1,
          items: [
            {
              __typename: 'ChecklistItem',
              id: convertToGraphQLId('Checklist::Item', 2),
              text: 'Checklist item B',
              ticketReference: {
                ticket: createDummyTicket(),
              },
              checked: false,
            },
          ],
        },
      })

      const view = await visitView('/tickets/1')
      await view.events.click(view.getByLabelText('Checklist'))

      const checklist = view.getByRole('heading', {
        name: 'Checklist',
        level: 2,
      })
      expect(checklist).toBeInTheDocument()

      // Checking display  of ticket link
      expect(
        view.getByRole('link', { name: 'Test Ticket' }),
      ).toBeInTheDocument()

      // Ticket link has single item menu, hence we have to test it does not exist in readonly
      expect(
        within(checklist).queryByRole('button', { name: 'Remove item' }),
      ).not.toBeInTheDocument()
    })

    it('updates incomplete checklist item count', async () => {
      mockTicketQuery({
        ticket: createDummyTicket({
          checklist: {
            id: convertToGraphQLId('Checklist', 1),
            complete: 1,
            completed: false,
            total: 2,
            incomplete: 1,
          },
        }),
      })

      const testArticle = createDummyArticle({
        bodyWithUrls: 'foobar',
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [{ node: testArticle }],
        },
        firstArticles: {
          edges: [{ node: testArticle }],
        },
      })

      mockApplicationConfig({ checklist: true })

      mockTicketChecklistQuery({
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: [
            {
              text: 'Item 1',
              checked: true,
              ticketReference: null,
            },
            {
              text: 'Item 2',
              checked: false,
              ticketReference: null,
            },
          ],
          incomplete: 1,
        },
      })

      const view = await visitView('/tickets/1')
      await view.events.click(view.getByLabelText('Checklist'))

      expect(
        view.getByRole('status', { name: 'Incomplete checklist items' }),
      ).toHaveTextContent('1')

      const checklistCheckboxes = view.getAllByRole('checkbox')

      await getTicketChecklistUpdatesSubscriptionHandler().trigger({
        ticketChecklistUpdates: {
          ticketChecklist: {
            id: convertToGraphQLId('Checklist', 1),
            name: 'Checklist title',
            items: [
              { text: 'Item 1', checked: true },
              { text: 'Item 2', checked: true },
            ],
            incomplete: 0,
          },
        },
      })

      await getTicketUpdatesSubscriptionHandler().trigger({
        ticketUpdates: {
          ticket: {
            checklist: {
              incomplete: 0,
            },
          },
        },
      })

      expect(
        view.queryByRole('status', { name: 'Incomplete checklist items' }),
      ).not.toBeInTheDocument()

      // Click manually in the frontend again on one of the checklist to show
      // the incomplete state again(without a subscription = manual cache update).
      await view.events.click(checklistCheckboxes[1])

      // FIXME: Does not come back, was this behavior changed?!
      // expect(
      //   await view.findByRole('status', { name: 'Incomplete checklist items' }),
      // ).toBeInTheDocument()
    })

    it('shows incomplete checklist dialog when ticket is being closed', async () => {
      mockApplicationConfig({
        checklist: true,
      })

      const ticket = createDummyTicket({
        state: {
          id: convertToGraphQLId('Ticket::State', 2),
          name: 'open',
          stateType: {
            id: convertToGraphQLId('TicketStateType', 2),
            name: 'open',
          },
        },
        articleType: 'email',
        defaultPolicy: {
          update: true,
          agentReadAccess: true,
        },
      })

      mockTicketQuery({
        ticket,
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

      await getNode('form-ticket-edit')?.settled

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            state_id: { value: 4 },
          },
        },
      })

      await view.events.click(await view.findByLabelText('State'))

      await view.events.click(
        await view.findByRole('option', { name: 'closed' }),
      )

      await getNode('form-ticket-edit')?.settled

      mockTicketUpdateMutation({
        ticketUpdate: {
          ticket: null,
          errors: [
            {
              message: 'The ticket checklist is incomplete.',
              exception:
                EnumUserErrorException.ServiceTicketUpdateValidatorChecklistCompletedError,
            },
          ],
        },
      })

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      await waitForTicketUpdateMutationCalls()

      let dialog = await view.findByRole('dialog', {
        name: 'Incomplete Ticket Checklist',
      })

      expect(
        within(dialog).getByRole('heading', {
          name: 'Incomplete Ticket Checklist',
          level: 3,
        }),
      ).toBeInTheDocument()

      expect(
        within(dialog).getByText(
          'You have unchecked items in the checklist. Do you want to handle them before closing this ticket?',
        ),
      ).toBeInTheDocument()

      await view.events.click(
        within(dialog).getByRole('button', {
          name: 'Yes, open the checklist',
        }),
      )

      const sidebar = await view.findByRole('complementary', {
        name: 'Content sidebar',
      })

      expect(
        within(sidebar).getByRole('heading', { name: 'Checklist', level: 2 }),
      ).toBeInTheDocument()

      expect(
        view.queryByRole('dialog', { name: 'Incomplete Ticket Checklist' }),
      ).not.toBeInTheDocument()

      expect(await view.findByRole('status', { name: 'Has update' }))

      await view.events.click(view.getByRole('button', { name: 'Ticket' }))

      expect(
        view.queryByRole('status', { name: 'Has update' }),
      ).not.toBeInTheDocument()

      const state = within(sidebar).getByLabelText('State')

      expect(within(state).getByRole('listitem')).toHaveTextContent('closed')

      expect(state.closest('.formkit-outer')).toHaveAttribute(
        'data-dirty',
        'true',
      )

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      dialog = await view.findByRole('dialog', {
        name: 'Incomplete Ticket Checklist',
      })

      mockTicketUpdateMutation({
        ticketUpdate: {
          ticket,
          errors: null,
        },
      })

      await view.events.click(
        within(dialog).getByRole('button', {
          name: 'No, just close the ticket',
        }),
      )

      await waitForTicketUpdateMutationCalls()

      expect(
        view.queryByRole('dialog', {
          name: 'Incomplete Ticket Checklist',
        }),
      ).not.toBeInTheDocument()

      expect(state.closest('.formkit-outer')).not.toHaveAttribute(
        'data-dirty',
        'true',
      )
    })
  })
})
