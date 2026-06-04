// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import TicketDetailScrollToBottomButton from '../TicketDetailScrollToBottomButton.vue'

const renderWrapper = (count: number) =>
  renderComponent(TicketDetailScrollToBottomButton, {
    props: { count },
  })

describe('TicketDetailScrollToBottomButton', () => {
  it('renders the scroll button with unread count', () => {
    const wrapper = renderWrapper(3)

    expect(wrapper.getByRole('button', { name: 'Scroll to bottom' })).toBeInTheDocument()
    expect(wrapper.getByRole('status', { name: 'Unread messages count' })).toHaveTextContent('3')
  })

  it('emits click when button is pressed', async () => {
    const wrapper = renderWrapper(1)

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Scroll to bottom' }))

    expect(wrapper.emitted('click')).toBeTruthy()
  })
})
