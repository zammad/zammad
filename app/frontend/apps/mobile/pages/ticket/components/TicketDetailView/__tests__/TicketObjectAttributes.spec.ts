// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import TicketObjectAttributes from '../TicketObjectAttributes.vue'

describe('TicketObjectAttributes', () => {
  it('renders the accounted time value if present', () => {
    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: 1,
          timeUnit: 11e-1,
        },
      },
    })

    const accountedTime = wrapper.getByLabelText('Accounted Time')

    expect(accountedTime).toHaveTextContent('1.1')
  })

  it('does not render an empty accounted time value', () => {
    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: 1,
          timeUnit: 0,
        },
      },
    })

    expect(wrapper.queryByLabelText('Accounted Time')).not.toBeInTheDocument()
  })

  it('renders the pre-defined time accounting unit', () => {
    mockApplicationConfig({
      time_accounting_unit: 'minute',
    })

    const wrapper = renderComponent(TicketObjectAttributes, {
      props: {
        ticket: {
          id: 1,
          timeUnit: 11e-1,
        },
      },
    })

    const accountedTime = wrapper.getByLabelText('Accounted Time')

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
          id: 1,
          timeUnit: 11e-1,
        },
      },
    })

    const accountedTime = wrapper.getByLabelText('Accounted Time')

    expect(accountedTime).toHaveTextContent('1.1 person day(s)')
  })
})
