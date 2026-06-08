// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import CommonTicketEscalationIndicatorItem from '../CommonTicketEscalationIndicatorItem.vue'

describe('CommonTicketEscalationIndicatorItem.vue', () => {
  it('renders given label', () => {
    const wrapper = renderComponent(CommonTicketEscalationIndicatorItem, {
      props: { label: 'test label', escalationTime: new Date().toISOString() },
    })

    expect(wrapper.getByText('test label')).toBeVisible()
  })

  it('renders past time as danger', () => {
    const wrapper = renderComponent(CommonTicketEscalationIndicatorItem, {
      props: {
        label: 'test label',
        escalationTime: new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 35).toISOString(),
      },
    })

    expect(wrapper.getByText('1 month ago')).toHaveClass('text-red-500')
  })

  it('renders future time as warning', () => {
    const wrapper = renderComponent(CommonTicketEscalationIndicatorItem, {
      props: {
        label: '',
        escalationTime: new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 35).toISOString(),
      },
    })

    expect(wrapper.getByText('in 1 month')).toHaveClass('text-yellow-600')
  })

  it('does not render label without valid time', () => {
    const wrapper = renderComponent(CommonTicketEscalationIndicatorItem, {
      props: {
        label: 'test label',
        escalationTime: null,
      },
    })

    expect(wrapper.container.querySelector('.text-yellow-600')).not.toBeInTheDocument()
    expect(wrapper.container.querySelector('.text-red-500')).not.toBeInTheDocument()
    expect(wrapper.queryByText('test label')).not.toBeInTheDocument()
  })
})
