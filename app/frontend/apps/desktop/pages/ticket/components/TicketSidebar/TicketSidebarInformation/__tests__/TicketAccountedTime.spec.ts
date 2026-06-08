// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { TicketQuery } from '#shared/graphql/types.ts'

import TicketAccountedTime from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketAccountedTime.vue'

const createTimeAccountingTicket = (
  timeUnitsPerType: TicketQuery['ticket']['timeUnitsPerType'] | [] = [],
  totalTimeCount: TicketQuery['ticket']['timeUnit'] = 11,
) => createDummyTicket({ timeUnit: totalTimeCount, timeUnitsPerType })

const timeUnitsPerType = [
  {
    name: 'None',
    timeUnit: 6,
    timeUnitDisplay: '6.00',
  },
  {
    name: 'Finance',
    timeUnit: 5,
    timeUnitDisplay: '5.00',
  },
  {
    name: 'Business',
    timeUnit: 4,
    timeUnitDisplay: '4.00',
  },
  {
    name: 'Development',
    timeUnit: 3,
    timeUnitDisplay: '3.00',
  },
  {
    name: 'Testing',
    timeUnit: 2,
    timeUnitDisplay: '2.00',
  },
  {
    name: 'Foo',
    timeUnit: 1,
    timeUnitDisplay: '1.00',
  },
]

describe('TicketAccountedTime', () => {
  it('should not display if there are no time records', () => {
    mockApplicationConfig({
      time_accounting_types: true,
    })

    const wrapper = renderComponent(TicketAccountedTime, {
      props: {
        ticket: createTimeAccountingTicket([], 0),
      },
    })

    expect(wrapper.baseElement.children).toHaveLength(1) // empty div
    expect(wrapper.baseElement).not.toHaveTextContent('Total')
  })

  it('should render a list of accounted time entries', () => {
    mockApplicationConfig({
      time_accounting_types: true,
    })

    const wrapper = renderComponent(TicketAccountedTime, {
      props: {
        ticket: createTimeAccountingTicket([
          {
            __typename: 'TicketTimeAccountingTypeSum',
            name: 'None',
            timeUnit: 3,
          },
        ]),
      },
    })

    expect(wrapper.getByText('Total')).toBeInTheDocument()

    expect(wrapper.getByText('3.00')).toBeInTheDocument()

    expect(wrapper.queryByRole('button')).not.toBeInTheDocument() // Show more button
  })

  it('should show a show more button if there are more than 4 entries', () => {
    mockApplicationConfig({
      time_accounting_types: true,
    })

    const wrapper = renderComponent(TicketAccountedTime, {
      props: {
        ticket: createTimeAccountingTicket(timeUnitsPerType, 22),
      },
    })

    expect(wrapper.getByRole('button')).toHaveTextContent('Show 3 more')

    timeUnitsPerType.forEach((value, index) => {
      if (index < 3) {
        expect(wrapper.getByText(value.name)).toBeInTheDocument()
        expect(wrapper.getByText(value.timeUnitDisplay)).toBeInTheDocument()
      } else {
        expect(wrapper.queryByText(value.name)).not.toBeInTheDocument()

        expect(wrapper.queryByText(value.timeUnitDisplay)).not.toBeInTheDocument()
      }
    })
  })

  it('shows all entries if show more button is clicked', async () => {
    await mockApplicationConfig({
      time_accounting_types: true,
    })

    const wrapper = renderComponent(TicketAccountedTime, {
      props: {
        ticket: createTimeAccountingTicket(timeUnitsPerType, 22),
      },
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    timeUnitsPerType.slice(3, -1).forEach((value) => {
      expect(wrapper.getByText(value.name)).toBeInTheDocument()
      expect(wrapper.getByText(value.timeUnitDisplay)).toBeInTheDocument()
    })
  })

  it('adds border under total count if more than one accounting type is available', () => {
    mockApplicationConfig({
      time_accounting_types: true,
    })

    const wrapper = renderComponent(TicketAccountedTime, {
      props: {
        ticket: createTimeAccountingTicket(timeUnitsPerType, 22),
      },
    })

    const listItems = wrapper.getAllByRole('listitem')

    expect(listItems[0]).toHaveClass('first:border-b first:border-solid dark:border-neutral-500')
  })

  it('adds border under total count if more than one accounting type is available', () => {
    mockApplicationConfig({
      time_accounting_types: true,
    })

    const wrapper = renderComponent(TicketAccountedTime, {
      props: {
        ticket: createTimeAccountingTicket([], 1),
      },
    })

    const listItems = wrapper.getAllByRole('listitem')

    expect(listItems[0]).not.toHaveClass(
      'first:border-b first:border-solid dark:border-neutral-500',
    )
  })
})
