// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import TicketSimpleTable from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/TicketSimpleTable.vue'

describe('TicketSimpleData', () => {
  it('displays a table with ticket data', () => {
    beforeEach(() => {
      // tell vitest we use mocked time
      vi.useFakeTimers()
    })

    mockApplicationConfig({
      ticket_hook: 'hook#',
    })
    const wrapper = renderComponent(TicketSimpleTable, {
      props: {
        tickets: [
          createDummyTicket({
            ticketId: '2',
            number: '1111',
            title: 'Dummy',
          }),
          createDummyTicket(),
        ],
        label: 'ROCK YOUR TICKET TABLE',
      },
      router: true,
    })

    // Labels
    expect(wrapper.getByText('hook#')).toBeInTheDocument()
    expect(wrapper.getByText('Title')).toBeInTheDocument()
    expect(wrapper.getByText('Customer')).toBeInTheDocument()
    expect(wrapper.getByText('Group')).toBeInTheDocument()
    expect(wrapper.getByText('Created at')).toBeInTheDocument()

    // Data
    expect(wrapper.getByText('ROCK YOUR TICKET TABLE')).toBeInTheDocument()
    expect(wrapper.getByText('89002')).toBeInTheDocument()
    expect(wrapper.getByText('1111')).toBeInTheDocument()
    expect(wrapper.getByText('Dummy')).toBeInTheDocument()
    expect(
      wrapper.getAllByRole('status', { name: 'check-circle-no' }),
    ).toHaveLength(2)
    expect(wrapper.getAllByText('Test Agents')).toHaveLength(2)
    expect(wrapper.getAllByText('2011-12-11')).toHaveLength(2)
  })

  it('emits table data on row click', async () => {
    const testTicket = createDummyTicket({
      ticketId: '2',
      number: '1111',
      title: 'Dummy',
    })
    const wrapper = renderComponent(TicketSimpleTable, {
      props: {
        tickets: [testTicket, createDummyTicket()],
        label: 'ROCK YOUR TICKET TABLE',
      },
      router: true,
    })

    await wrapper.events.click(wrapper.getByText('1111'))

    expect(wrapper.emitted('click-ticket')).toBeTruthy()
  })
})
