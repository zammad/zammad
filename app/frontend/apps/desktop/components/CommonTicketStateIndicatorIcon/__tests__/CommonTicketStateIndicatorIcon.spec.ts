// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import CommonTicketStateIndicatorIcon from '../CommonTicketStateIndicatorIcon.vue'

import type { Props } from '../CommonTicketStateIndicatorIcon.vue'

const renderCommonTicketStateIndicatorIcon = (props: Partial<Props> = {}) => {
  return renderComponent(CommonTicketStateIndicatorIcon, {
    props: {
      ...props,
    },
  })
}

describe('CommonTicketStateIndicator.vue', () => {
  it('renders open state correctly', () => {
    const view = renderCommonTicketStateIndicatorIcon({
      colorCode: EnumTicketStateColorCode.Open,
      label: 'open',
    })

    expect(view.getByIconName('check-circle-no')).toBeInTheDocument()
  })

  it('renders pending state correctly', () => {
    const view = renderCommonTicketStateIndicatorIcon({
      colorCode: EnumTicketStateColorCode.Pending,
      label: 'pending reminder',
    })

    expect(
      view.getByIconName('check-circle-outline-dashed'),
    ).toBeInTheDocument()
  })

  it('renders escalated state correctly', () => {
    const view = renderCommonTicketStateIndicatorIcon({
      colorCode: EnumTicketStateColorCode.Escalating,
      label: 'new',
    })

    expect(view.getByIconName('warning-triangle')).toBeInTheDocument()
  })

  it('renders closed state correctly', () => {
    const view = renderCommonTicketStateIndicatorIcon({
      colorCode: EnumTicketStateColorCode.Closed,
      label: 'closed',
    })

    expect(view.getByIconName('check-circle-outline')).toBeInTheDocument()
  })
})
