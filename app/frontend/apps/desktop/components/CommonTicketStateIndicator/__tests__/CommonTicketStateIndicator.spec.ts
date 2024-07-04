// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import CommonTicketStateIndicator from '../CommonTicketStateIndicator.vue'

import type { Props } from '../CommonTicketStateIndicator.vue'

const renderCommonTicketStateIndicator = (props: Partial<Props> = {}) => {
  return renderComponent(CommonTicketStateIndicator, {
    props: {
      ...props,
    },
  })
}

describe('CommonTicketStateIndicator.vue', () => {
  it('renders open state correctly', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Open,
      label: 'open',
    })

    expect(view.getByRole('group')).toHaveClass('common-badge-warning')
    expect(view.getByRole('group')).toHaveTextContent('open')
  })

  it('renders pending state correctly', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Pending,
      label: 'pending reminder',
    })

    expect(view.getByRole('group')).toHaveClass('common-badge-tertiary')
    expect(view.getByRole('group')).toHaveTextContent('pending reminder')
  })

  it('renders escalated state correctly', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Escalating,
      label: 'new',
    })

    expect(view.getByRole('group')).toHaveClass('common-badge-danger')
    expect(view.getByRole('group')).toHaveTextContent('new')
  })

  it('renders closed state correctly', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Closed,
      label: 'closed',
    })

    expect(view.getByRole('group')).toHaveClass('common-badge-success')
    expect(view.getByRole('group')).toHaveTextContent('closed')
  })
})
