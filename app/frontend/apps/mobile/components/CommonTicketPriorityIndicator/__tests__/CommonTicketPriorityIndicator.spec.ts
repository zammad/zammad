// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonTicketPriorityIndicator from '../CommonTicketPriorityIndicator.vue'

import type { Props } from '../CommonTicketPriorityIndicator.vue'

const renderCommonTicketPriorityIndicator = (props: Partial<Props> = {}) => {
  return renderComponent(CommonTicketPriorityIndicator, {
    props: {
      ...props,
    },
  })
}

describe('CommonTicketPriorityIndicator.vue', () => {
  it('renders low priority correctly', () => {
    const view = renderCommonTicketPriorityIndicator({
      priority: {
        defaultCreate: false,
        name: '1 low',
        uiColor: 'low-priority',
      },
    })

    expect(view.getByText('1 low')).toHaveClasses([
      'bg-blue-highlight',
      'text-blue',
    ])
  })

  it('renders high priority correctly', () => {
    const view = renderCommonTicketPriorityIndicator({
      priority: {
        defaultCreate: false,
        name: '3 high',
        uiColor: 'high-priority',
      },
    })

    expect(view.getByText('3 high')).toHaveClasses([
      'bg-red-dark',
      'text-red-bright',
    ])
  })

  it('does not render default priority', () => {
    const view = renderCommonTicketPriorityIndicator({
      priority: {
        defaultCreate: true,
        name: '2 normal',
        uiColor: null,
      },
    })

    expect(view.queryByText('2 normal')).not.toBeInTheDocument()
  })
})
