// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import TicketSimpleTable from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/TicketSimpleTable.vue'

describe('TicketSimpleData', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  it('displays a table with ticket data', () => {
    mockApplicationConfig({ ticket_hook: 'Ticket#' })

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
      form: true,
      router: true,
    })

    // Labels
    expect(wrapper.getByText('Ticket#')).toBeInTheDocument()
    expect(wrapper.getByText('Title')).toBeInTheDocument()
    expect(wrapper.getByText('Customer')).toBeInTheDocument()
    expect(wrapper.getByText('Group')).toBeInTheDocument()
    expect(wrapper.getByText('Created at')).toBeInTheDocument()

    // Data
    expect(wrapper.getByText('ROCK YOUR TICKET TABLE')).toBeInTheDocument()
    expect(wrapper.getByText('89002')).toBeInTheDocument()
    expect(wrapper.getByText('1111')).toBeInTheDocument()
    expect(wrapper.getByText('1111')).toHaveAttribute(
      'href',
      '/desktop/tickets/2',
    )
    expect(wrapper.getByText('Dummy')).toBeInTheDocument()
    expect(
      wrapper.getAllByRole('status', { name: 'check-circle-no' }),
    ).toHaveLength(2)
    expect(wrapper.getAllByText('Test Agents')).toHaveLength(2)
    expect(wrapper.getAllByText('2011-12-11')).toHaveLength(2)
  })

  it('emits table data on row click', async () => {
    const fullTicket = createDummyTicket({
      ticketId: '2',
      number: '1111',
      title: 'Dummy',
    })

    const ticket = {
      id: fullTicket.id,
      internalId: fullTicket.internalId,
      createdAt: fullTicket.createdAt,
      organization: {
        name: fullTicket.organization?.name,
        id: fullTicket.organization?.id,
      },
      customer: {
        fullname: fullTicket.customer.fullname,
        id: fullTicket.customer.id,
      },
      group: {
        name: fullTicket.group?.name,
        id: fullTicket.group.id,
      },
      state: fullTicket.state,
      number: fullTicket.number,
      stateColorCode: fullTicket.stateColorCode,
      title: fullTicket.title,
    }

    const wrapper = renderComponent(TicketSimpleTable, {
      props: {
        tickets: [ticket],
        label: 'ROCK YOUR TICKET TABLE',
      },
      form: true,
      router: true,
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Select table row' }),
    )

    expect(wrapper.emitted('click-ticket')).toStrictEqual([[ticket]])
  })

  it('marks ticket row as active if ticket got selected', () => {
    const testTicket = createDummyTicket({
      ticketId: '2',
      number: '1111',
      title: 'Dummy',
    })

    const wrapper = renderComponent(TicketSimpleTable, {
      props: {
        tickets: [testTicket],
        selectedTicketId: testTicket.id,
        label: 'ROCK YOUR TICKET TABLE',
      },
      form: true,
      router: true,
    })

    expect(
      wrapper.getByRole('button', { name: 'Select table row' }),
    ).toHaveClass(
      'odd:bg-blue-200 odd:dark:bg-gray-700 !bg-blue-800 group focus-visible:outline-transparent cursor-pointer active:bg-blue-800 active:dark:bg-blue-800 focus-visible:bg-blue-800 focus-visible:dark:bg-blue-900 focus-within:text-white hover:bg-blue-600 dark:hover:bg-blue-900',
    )
  })
})
