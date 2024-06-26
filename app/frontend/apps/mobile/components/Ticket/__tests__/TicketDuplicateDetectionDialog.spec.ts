// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type { TicketDuplicateDetectionItem } from '#shared/entities/ticket/types.ts'

import TicketDuplicateDetectionDialog from '../TicketDuplicateDetectionDialog.vue'

describe('TicketDuplicateDetectionDialog.vue', () => {
  beforeEach(() => {
    mockApplicationConfig({
      ticket_duplicate_detection_title: 'Foo',
      ticket_duplicate_detection_body: 'Bar',
    })
  })

  it('renders configured title and message', () => {
    const view = renderComponent(TicketDuplicateDetectionDialog, {
      props: {
        name: 'duplicate-ticket-detection',
        tickets: [],
      },
    })

    expect(view.getByText('Foo')).toBeInTheDocument()
    expect(view.getByText('Bar')).toBeInTheDocument()
  })

  it('renders provided ticket items', () => {
    const testTickets: TicketDuplicateDetectionItem[] = [
      [1, '27001', 'Test Ticket 1'],
      [2, '27002', 'Test Ticket 2'],
      [3, '27003', 'Test Ticket 3'],
      [4, '27004', 'Test Ticket 4'],
      [5, '27005', 'Test Ticket 5'],
    ]

    const view = renderComponent(TicketDuplicateDetectionDialog, {
      props: {
        name: 'duplicate-ticket-detection',
        tickets: testTickets,
      },
      router: true,
    })

    testTickets.forEach((testTicket) => {
      const ticketNumber = `#${testTicket[1]}`
      const ticketNumberElement = view.getByText(ticketNumber)

      expect(ticketNumberElement).toBeInTheDocument()

      expect(ticketNumberElement.closest('a')).toHaveAttribute(
        'href',
        `/tickets/${testTicket[0]}`,
      )

      const ticketTitle = testTicket[2]

      expect(view.getByText(ticketTitle)).toBeInTheDocument()
    })
  })
})
