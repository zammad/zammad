// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketObjectAttributes from '../TicketObjectAttributes.vue'

describe('TicketObjectAttributes', () => {
  it('renders the accounted time value if present', () => {
    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: convertToGraphQLId('Ticket', 1),
          timeUnit: 11e-1,
          timeUnitsPerType: [],
        },
      },
    })

    const accountedTime = wrapper.getByLabelText('Total Accounted Time')

    expect(accountedTime).toHaveTextContent('1.1')

    expect(wrapper.queryByText('none')).not.toBeInTheDocument()
    expect(
      wrapper.queryByRole('button'),
      'no "show more" button',
    ).not.toBeInTheDocument()
  })

  it('does not render an empty accounted time value', () => {
    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: convertToGraphQLId('Ticket', 1),
          timeUnit: 0,
          timeUnitsPerType: null,
        },
      },
    })

    expect(
      wrapper.queryByLabelText('Total Accounted Time'),
    ).not.toBeInTheDocument()
  })

  it('renders the pre-defined time accounting unit', () => {
    mockApplicationConfig({
      time_accounting_unit: 'minute',
    })

    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: convertToGraphQLId('Ticket', 1),
          timeUnit: 11e-1,
          timeUnitsPerType: [],
        },
      },
    })

    const accountedTime = wrapper.getByLabelText('Total Accounted Time')

    expect(accountedTime).toHaveTextContent('1.1 minute(s)')
  })

  it('renders the custom time accounting unit', () => {
    mockApplicationConfig({
      time_accounting_unit: 'custom',
      time_accounting_unit_custom: 'person day(s)',
    })

    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: convertToGraphQLId('Ticket', 1),
          timeUnit: 11e-1,
          timeUnitsPerType: [],
        },
      },
    })

    const accountedTime = wrapper.getByLabelText('Total Accounted Time')

    expect(accountedTime).toHaveTextContent('1.1 person day(s)')
  })

  const formatTimeUnits = (element: HTMLElement) => {
    return element.textContent?.split(')').join(')\n')
  }

  it('does not render a list of time unit entries if not configured', () => {
    mockApplicationConfig({
      time_accounting_types: false,
    })

    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: convertToGraphQLId('Ticket', 1),
          timeUnit: 11e-1 + 101e-1 + 21e-1 + 300e-1 + 20e-1, // 45.3
          timeUnitsPerType: [
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 2),
              timeUnit: 101e-1 + 21e-1 + 300e-1,
              name: 'billable',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 3),
              timeUnit: 20e-1,
              name: 'not billable',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 1),
              timeUnit: 11e-1,
              name: 'None',
            },
          ],
        },
      },
    })

    expect(wrapper.queryByTestId('timeUnitsEntries')).not.toBeInTheDocument()
  })

  it('renders a list of time unit entries', () => {
    mockApplicationConfig({
      time_accounting_unit: 'minute',
      time_accounting_types: true,
    })

    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: convertToGraphQLId('Ticket', 1),
          timeUnit: 11e-1 + 101e-1 + 21e-1 + 300e-1 + 20e-1, // 45.3
          timeUnitsPerType: [
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 2),
              timeUnit: 101e-1 + 21e-1 + 300e-1,
              name: 'billable',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 3),
              timeUnit: 20e-1,
              name: 'not billable',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 1),
              timeUnit: 11e-1,
              name: 'None',
            },
          ],
        },
      },
    })

    const entriesElement = wrapper.getByTestId('timeUnitsEntries')
    // correctly sorted with highest at the top
    expect(formatTimeUnits(entriesElement)).toMatchInlineSnapshot(
      `
      "Billable42.2 minute(s)
      Not billable2 minute(s)
      None1.1 minute(s)
      "
    `,
    )

    expect(
      wrapper.queryByRole('button'),
      'no "show more" button',
    ).not.toBeInTheDocument()
  })

  it('shows a button to show more', async () => {
    mockApplicationConfig({
      time_accounting_unit: 'minute',
      time_accounting_types: true,
    })

    const view = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: convertToGraphQLId('Ticket', 1),
          timeUnit: 11e-1,
          timeUnitsPerType: [
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 2),
              timeUnit: 101e-1,
              name: 'name I - ',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 4),
              timeUnit: 40e-1,
              name: 'name III - ',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 5),
              timeUnit: 30e-1,
              name: 'name IV - ',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 3),
              timeUnit: 20e-1,
              name: 'name II - ',
            },
            {
              id: convertToGraphQLId('TicketTimeUnitEntry', 1),
              timeUnit: 11e-1,
              name: 'None',
            },
          ],
        },
      },
    })

    const entriesElement = view.getByTestId('timeUnitsEntries')
    expect(formatTimeUnits(entriesElement)).toMatchInlineSnapshot(
      `
      "Name I - 10.1 minute(s)
      Name III - 4 minute(s)
      Name IV - 3 minute(s)
      "
    `,
    )

    const buttonShowMore = view.getByRole('button', { name: 'Show 2 more' })

    await view.events.click(buttonShowMore)

    expect(formatTimeUnits(entriesElement)).toMatchInlineSnapshot(
      `
      "Name I - 10.1 minute(s)
      Name III - 4 minute(s)
      Name IV - 3 minute(s)
      Name II - 2 minute(s)
      None1.1 minute(s)
      "
    `,
    )
  })
})
