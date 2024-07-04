// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Props } from '../CommonTicketEscalationIndicator.vue'

const now = new Date('2023-02-28 12:00:00')
vi.useFakeTimers().setSystemTime(now)

const { renderComponent } = await import('#tests/support/components/index.ts')
const { default: CommonTicketEscalationIndicator } = await import(
  '../CommonTicketEscalationIndicator.vue'
)

export {}

const renderCommonTicketEscalationIndicator = (props: Partial<Props> = {}) => {
  return renderComponent(CommonTicketEscalationIndicator, {
    props: {
      ...props,
    },
  })
}

describe('CommonTicketEscalationIndicator.vue', () => {
  afterAll(() => {
    vi.useRealTimers()
  })

  it('renders running escalation correctly', () => {
    const view = renderCommonTicketEscalationIndicator({
      escalationAt: new Date('2023-02-28 11:00:00').toISOString(),
    })

    const alert = view.getByRole('alert')

    expect(alert).toHaveClass('common-badge-danger')
    expect(alert).toHaveTextContent('escalation 1 hour ago')
  })

  it('renders warning escalation correctly', () => {
    const view = renderCommonTicketEscalationIndicator({
      escalationAt: new Date('2023-02-28 13:00:00').toISOString(),
    })

    const alert = view.getByRole('alert')

    expect(alert).toHaveClass('common-badge-warning')
    expect(alert).toHaveTextContent('escalation in 1 hour')
  })

  it('renders unknown escalation correctly', () => {
    const view = renderCommonTicketEscalationIndicator({
      escalationAt: 'foobar',
    })

    expect(view.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('renders undefined escalation correctly', () => {
    const view = renderCommonTicketEscalationIndicator({
      escalationAt: undefined,
    })

    expect(view.queryByRole('alert')).not.toBeInTheDocument()
  })
})
