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

    expect(view.getByRole('group')).toHaveClass('text-yellow')
    expect(view.getByIconName('check-circle-no')).toHaveAccessibleName(
      '(state: open)',
    )
  })

  it('renders pending state correctly', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Pending,
      label: 'pending reminder',
    })

    expect(view.getByRole('group')).toHaveClass('text-gray')
    expect(view.getByIconName('check-circle-no')).toHaveAccessibleName(
      '(state: pending reminder)',
    )
  })

  it('renders escalated state correctly', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Escalating,
      label: 'new',
    })

    expect(view.getByRole('group')).toHaveClass('text-red-bright')
    expect(view.getByIconName('check-circle-no')).toHaveAccessibleName(
      '(state: new)',
    )
  })

  it('renders closed state correctly', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Closed,
      label: 'closed',
    })

    expect(view.getByRole('group')).toHaveClass('text-green')
    expect(view.getByIconName('check-circle-no')).toHaveAccessibleName(
      '(state: closed)',
    )
  })

  it('renders open state correctly (pill)', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Open,
      label: 'open',
      pill: true,
    })

    const statusIndicator = view.getByRole('group')

    expect(statusIndicator).toHaveClasses([
      'bg-yellow-highlight',
      'text-yellow',
    ])
    expect(statusIndicator).toHaveTextContent('open')
  })

  it('renders pending state correctly (pill)', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Pending,
      label: 'pending reminder',
      pill: true,
    })

    const statusIndicator = view.getByRole('group')

    expect(statusIndicator).toHaveClasses(['bg-gray-highlight', 'text-gray'])
    expect(statusIndicator).toHaveTextContent('pending reminder')
  })

  it('renders escalated state correctly (pill)', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Escalating,
      label: 'new',
      pill: true,
    })

    const statusIndicator = view.getByRole('group')

    expect(statusIndicator).toHaveClasses(['bg-red-dark', 'text-red-bright'])
    expect(statusIndicator).toHaveTextContent('new')
  })

  it('renders closed state correctly (pill)', () => {
    const view = renderCommonTicketStateIndicator({
      colorCode: EnumTicketStateColorCode.Closed,
      label: 'closed',
      pill: true,
    })

    const statusIndicator = view.getByRole('group')

    expect(statusIndicator).toHaveClasses(['bg-green-highlight', 'text-green'])
    expect(statusIndicator).toHaveTextContent('closed')
  })
})
