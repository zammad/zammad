// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockTodaysTicketsQuery } from '../../graphql/queries/todaysTickets.mocks.ts'
import TodaysTicketsWidget from '../TodaysTicketsWidget.vue'

const renderTodaysTicketsWidget = async () => {
  const wrapper = renderComponent(TodaysTicketsWidget, {
    store: true,
  })

  await waitForNextTick()

  return wrapper
}

describe('TodaysTicketsWidget', () => {
  beforeEach((context) => {
    context.skipConsole = true
  })

  describe('widget structure', () => {
    it('renders widget header and controls', async () => {
      mockTodaysTicketsQuery({
        todaysTickets: []
      })

      const wrapper = await renderTodaysTicketsWidget()

      expect(wrapper.getByText("Today's Tickets")).toBeInTheDocument()
      expect(wrapper.getByText('Auto-refresh every 30 seconds')).toBeInTheDocument()
      expect(wrapper.getByRole('button', { name: 'Refresh tickets' })).toBeInTheDocument()
    })

    it('shows loading state while loading', async () => {
      mockTodaysTicketsQuery({
        todaysTickets: []
      })

      const wrapper = renderComponent(TodaysTicketsWidget, { store: true })
      
      expect((await wrapper).getByText('Loading tickets...')).toBeInTheDocument()
    })

    it('renders widget without crashing with ticket data', async () => {
      mockTodaysTicketsQuery({
        todaysTickets: [
          {
            id: convertToGraphQLId('Ticket', 123),
            number: '12345',
            title: 'Test Support Ticket',
            stateColorCode: EnumTicketStateColorCode.Open,
            createdAt: '2025-01-07T10:00:00Z',
            updatedAt: '2025-01-07T10:00:00Z',
            state: {
              id: convertToGraphQLId('Ticket::State', 1),
              name: 'open'
            },
            priority: {
              id: convertToGraphQLId('Ticket::Priority', 2),
              name: 'normal',
              uiColor: 'low-priority'
            },
            customer: {
              id: convertToGraphQLId('User', 1),
              fullname: 'John Doe',
              email: 'john@example.com'
            },
            owner: {
              id: convertToGraphQLId('User', 2),
              fullname: 'Jane Smith'
            },
            group: {
              id: convertToGraphQLId('Group', 1),
              name: 'Support'
            }
          }
        ]
      })

      const wrapper = await renderTodaysTicketsWidget()

      expect(wrapper.container).toBeInTheDocument()
      expect(wrapper.getByText("Today's Tickets")).toBeInTheDocument()
    })

    it('handles empty data state', async () => {
      mockTodaysTicketsQuery({
        todaysTickets: []
      })

      const wrapper = await renderTodaysTicketsWidget()

      expect(wrapper.container).toBeInTheDocument()
      expect(wrapper.getByText("Today's Tickets")).toBeInTheDocument()
      
      const mainDiv = wrapper.container.querySelector('.flex.flex-col.gap-2\\.5')
      expect(mainDiv).toBeInTheDocument()
    })
  })
})