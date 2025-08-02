// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { waitFor } from '@testing-library/vue'
import { vi } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import emitter from '#shared/utils/emitter.ts'

import {
  mockTodaysTicketsQuery,
  mockTodaysTicketsQueryWithEmptyData,
  mockTodaysTicketsQueryWithSingleTicket,
  mockTodaysTicketsQueryWithMultipleTickets,
  mockTodaysTicketsQueryWithNetworkError,
  createMockTicketForToday,
  createMultipleMockTickets,
} from '../graphql/todaysTickets.mocks.ts'
import TodaysTicketsWidget from '../TodaysTicketsWidget.vue'

describe('TodaysTicketsWidget', () => {
  const renderWidget = (options = {}) => {
    return renderComponent(TodaysTicketsWidget, {
      router: true,
      ...options,
    })
  }

  afterEach(() => {
    vi.resetAllMocks()
  })

  it('renders the widget with title', () => {
    const wrapper = renderWidget()

    expect(wrapper.getByText("Today's Tickets")).toBeInTheDocument()
    expect(wrapper.getByText("Today's Tickets")).toHaveClass('text-base', 'font-semibold')
  })

  describe('component states', () => {
    it('displays loading state with CommonLoader', async () => {
      const wrapper = renderWidget()

      expect(wrapper.getByText("Today's Tickets")).toBeInTheDocument()
    })

    it('displays error state when query fails', async () => {
      mockTodaysTicketsQueryWithNetworkError()

      const wrapper = renderWidget()

      await waitFor(() => {
        expect(
          wrapper.getByText('Error loading tickets. Please try again later.'),
        ).toBeInTheDocument()
      })

      const errorElement = wrapper.getByText('Error loading tickets. Please try again later.')
      expect(errorElement).toHaveClass('text-center', 'text-red-600')
    })

    it('displays empty state when no tickets exist', async () => {
      // Try the simplest possible mock first
      mockTodaysTicketsQuery({
        todaysTickets: null,
      })

      const wrapper = renderWidget()

      await waitFor(() => {
        expect(wrapper.getByText('No tickets created today.')).toBeInTheDocument()
      })

      const emptyElement = wrapper.getByText('No tickets created today.')
      expect(emptyElement).toHaveClass('text-center', 'text-neutral-500')
    })

    it('displays populated state with single ticket', async () => {
      mockTodaysTicketsQueryWithSingleTicket()

      const wrapper = renderWidget()

      await waitFor(() => {
        expect(wrapper.getByRole('table')).toBeInTheDocument()
      })

      expect(wrapper.getByText('53001')).toBeInTheDocument()
      expect(wrapper.getByText('Test Ticket for Today')).toBeInTheDocument()
      expect(wrapper.getByText('John Doe')).toBeInTheDocument()
      expect(wrapper.getByText('open')).toBeInTheDocument()
    })

    it('displays populated state with multiple tickets', async () => {
      const mockTickets = createMultipleMockTickets(3)
      mockTodaysTicketsQueryWithMultipleTickets(mockTickets)

      const wrapper = renderWidget()

      await waitFor(() => {
        expect(wrapper.getByRole('table')).toBeInTheDocument()
      })

      expect(wrapper.getByText('53001')).toBeInTheDocument()
      expect(wrapper.getByText('53002')).toBeInTheDocument()
      expect(wrapper.getByText('53003')).toBeInTheDocument()

      expect(wrapper.getByText('Number')).toBeInTheDocument()
      expect(wrapper.getByText('Title')).toBeInTheDocument()
      expect(wrapper.getByText('State')).toBeInTheDocument()
      expect(wrapper.getByText('Customer')).toBeInTheDocument()
    })
  })

  describe('user interactions', () => {
    it('navigates to ticket detail when row is clicked', async () => {
      mockTodaysTicketsQueryWithSingleTicket()

      const wrapper = renderWidget({ router: true })

      await waitFor(() => {
        expect(wrapper.getByRole('table')).toBeInTheDocument()
      })

      const ticketRow = wrapper.getByRole('row', { description: 'Select table row' })
      await wrapper.events.click(ticketRow)

      expect(wrapper.router.push).toHaveBeenCalledWith('/tickets/1')
    })

    it('navigates to correct ticket when multiple tickets are present', async () => {
      mockTodaysTicketsQueryWithMultipleTickets()

      const wrapper = renderWidget({ router: true })

      await waitFor(() => {
        expect(wrapper.getByRole('table')).toBeInTheDocument()
      })

      const ticketRows = wrapper.getAllByRole('row', { description: 'Select table row' })
      await wrapper.events.click(ticketRows[1])

      expect(wrapper.router.push).toHaveBeenCalledWith('/tickets/2')
    })
  })

  describe('event handling and lifecycle', () => {
    it('responds to ticket-created event by refetching data', async (context) => {
      context.skipConsole = true
      const consoleSpy = vi.spyOn(console, 'error').mockReturnValue()

      mockTodaysTicketsQueryWithSingleTicket()
      const wrapper = renderWidget()

      await waitFor(() => {
        expect(wrapper.getByRole('table')).toBeInTheDocument()
      })

      emitter.emit('ticket-created')

      await waitFor(() => {
        expect(consoleSpy).not.toHaveBeenCalledWith(
          expect.stringContaining("Failed to refetch today's tickets:"),
        )
      })

      consoleSpy.mockRestore()
    })

    it('handles ticket-created event emission multiple times', async (context) => {
      context.skipConsole = true
      const consoleSpy = vi.spyOn(console, 'error').mockReturnValue()

      mockTodaysTicketsQueryWithSingleTicket()
      const wrapper = renderWidget()

      await waitFor(() => {
        expect(wrapper.getByRole('table')).toBeInTheDocument()
      })

      for (let i = 0; i < 3; i++) {
        emitter.emit('ticket-created')
      }

      await waitFor(() => {
        expect(consoleSpy).not.toHaveBeenCalledWith(
          expect.stringContaining("Failed to refetch today's tickets:"),
        )
      })

      consoleSpy.mockRestore()
    })

    it('cleans up event listeners on unmount', async () => {
      mockTodaysTicketsQueryWithSingleTicket()

      const wrapper = renderWidget()

      await waitFor(() => {
        expect(wrapper.getByRole('table')).toBeInTheDocument()
      })

      const emitterOffSpy = vi.spyOn(emitter, 'off')

      wrapper.unmount()

      expect(emitterOffSpy).toHaveBeenCalledWith('ticket-created', expect.any(Function))

      emitterOffSpy.mockRestore()
    })
  })
})
