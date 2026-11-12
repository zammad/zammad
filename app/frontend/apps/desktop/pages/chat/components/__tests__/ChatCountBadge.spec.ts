// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import ChatCountBadge from '../ChatCountBadge.vue'

describe('ChatCountBadge', () => {
  it('sends a ring out of the badge while highlighted and above zero, unless reduced motion is asked for', () => {
    const view = renderComponent(ChatCountBadge, { props: { count: 2, highlight: true } })

    expect(view.container.querySelector('.animate-sonar')).toHaveClass('motion-reduce:hidden')
    expect(view.getByText('2')).not.toHaveClass('animate-sonar')
  })

  it.each([
    { count: 0, highlight: true },
    { count: 2, highlight: false },
  ])('has no ring for count $count and highlight $highlight', (props) => {
    const view = renderComponent(ChatCountBadge, { props })

    expect(view.container.querySelector('.animate-sonar')).not.toBeInTheDocument()
  })
})
