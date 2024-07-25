// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import DeliveryMessage from '#desktop/pages/ticket/components/TicketDetailView/DeliveryMessage.vue'

const renderWrapper = (content: string) => {
  return renderComponent(DeliveryMessage, { router: true, props: { content } })
}

describe('DeliveryMessage', () => {
  it('creates the component with enabled button', () => {
    const wrapper = renderWrapper('something went wrong')

    expect(
      wrapper.queryByText('Delivery failed: "something went wrong"'),
    ).toBeInTheDocument()
  })
})
