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
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumUserErrorException } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })
  })

  describe('Time accounting', () => {
    it('shows accounted time information in sidebar', async () => {
      await mockApplicationConfig({
        time_accounting_types: true,
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
        timeUnit: 15,
        timeUnitsPerType: [
          {
            name: 'None',
            timeUnit: 6,
          },
          {
            name: 'Finance',
            timeUnit: 5,
          },
          {
            name: 'Business',
            timeUnit: 4,
          },
        ],
      })

      mockTicketQuery({
        ticket,
      })

      const view = await visitView('/tickets/1')

      const sidebar = view.getByLabelText('Content sidebar')

      expect(
        within(sidebar).getByRole('heading', {
          level: 3,
          name: 'Accounted Time',
        }),
      ).toBeInTheDocument()

      expect(within(sidebar).getByText('Total')).toBeInTheDocument()
      expect(within(sidebar).getByText('15')).toBeInTheDocument()
    })

    it('opens time accounting flyout when the condition is met', async () => {
      mockApplicationConfig({
        ui_ticket_zoom_article_note_new_internal: true,
        time_accounting: true,
        time_accounting_unit: '',
        time_accounting_types: false,
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

      await view.events.click(
        await view.findByRole('button', { name: 'Add internal note' }),
      )

      await view.events.type(
        await view.findByRole('textbox', { name: 'Text' }),
        'Foo note',
      )

      mockTicketUpdateMutation({
        ticketUpdate: {
          ticket: null,
          errors: [
            {
              message: 'The ticket time accounting condition is met.',
              exception:
                EnumUserErrorException.ServiceTicketUpdateValidatorTimeAccountingError,
            },
          ],
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {},
        },
      })

      await view.events.click(
        await view.findByRole('button', { name: 'Update' }),
      )

      await waitForTicketUpdateMutationCalls()

      const flyout = await view.findByRole('complementary', {
        name: 'Time Accounting',
      })

      expect(
        within(flyout).getByRole('heading', {
          level: 2,
        }),
      ).toHaveTextContent('Time Accounting')

      await view.events.type(
        await within(flyout).findByLabelText('Accounted Time'),
        '1',
      )

      await getNode('form-ticket-time-accounting')?.settled

      mockTicketUpdateMutation({
        ticketUpdate: {
          ticket,
          errors: null,
        },
      })

      await view.events.click(
        within(flyout).getByRole('button', {
          name: 'Account Time',
        }),
      )

      const calls = await waitForTicketUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          input: expect.objectContaining({
            article: expect.objectContaining({
              timeUnit: 1,
            }),
          }),
        }),
      )

      expect(
        view.queryByRole('complementary', {
          name: 'Time Accounting',
        }),
      ).not.toBeInTheDocument()
    })
  })
})
