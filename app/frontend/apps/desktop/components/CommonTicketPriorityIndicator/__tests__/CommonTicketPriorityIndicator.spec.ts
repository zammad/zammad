// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { getConfigUpdatesSubscriptionHandler } from '#shared/graphql/subscriptions/configUpdates.mocks.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

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

    expect(view.getByText('1 low')).toHaveClass('common-badge-info')
  })

  it('renders high priority correctly', () => {
    const view = renderCommonTicketPriorityIndicator({
      priority: {
        defaultCreate: false,
        name: '3 high',
        uiColor: 'high-priority',
      },
    })

    expect(view.getByText('3 high')).toHaveClass('common-badge-danger')
  })

  it('does not render default priority', () => {
    const view = renderCommonTicketPriorityIndicator({
      priority: {
        defaultCreate: true,
        name: '2 normal',
        uiColor: null,
      },
    })

    expect(view.getByText('2 normal')).toHaveClass('common-badge-warning')
  })

  it('supports accessibility features', () => {
    const view = renderCommonTicketPriorityIndicator({
      priority: {
        defaultCreate: true,
        name: '2 normal',
        uiColor: null,
      },
    })

    const status = view.getByRole('status')

    expect(status).toHaveAttribute('aria-live', 'polite')
    expect(status).toHaveTextContent('2 normal')
  })

  it('supports rendering priority icons', async () => {
    mockApplicationConfig({
      ui_ticket_priority_icons: true,
    })

    const view = renderCommonTicketPriorityIndicator({
      priority: {
        defaultCreate: true,
        name: '2 normal',
        uiColor: null,
      },
    })

    expect(view.getByIconName('priority-normal')).toBeInTheDocument()

    await view.rerender({
      priority: {
        defaultCreate: false,
        name: '3 high',
        uiColor: 'high-priority',
      },
    })

    expect(view.getByIconName('priority-high')).toBeInTheDocument()

    await view.rerender({
      priority: {
        defaultCreate: false,
        name: '1 low',
        uiColor: 'low-priority',
      },
    })

    expect(view.getByIconName('priority-low')).toBeInTheDocument()

    const { initializeConfigUpdateSubscription } = useApplicationStore()

    initializeConfigUpdateSubscription()

    await getConfigUpdatesSubscriptionHandler().trigger({
      configUpdates: {
        setting: {
          key: 'ui_ticket_priority_icons',
          value: false,
        },
      },
    })

    expect(view.queryByIconName('priority-low')).not.toBeInTheDocument()
  })
})
