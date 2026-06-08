// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'

describe('CommonEmptyMessage', () => {
  it('renders empty text', () => {
    const wrapper = renderComponent(CommonEmptyMessage, {
      props: {
        title: 'No tickets found',
        text: 'Nothing to golden to find in this overview.',
      },
    })

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('No tickets found')

    expect(wrapper.getByText('Nothing to golden to find in this overview.')).toBeInTheDocument()
  })

  it('render with illustration', () => {
    const wrapper = renderComponent(CommonEmptyMessage, {
      props: {
        title: 'No tickets found',
        text: 'Nothing to golden to find in this overview.',
        withIllustration: true,
      },
    })

    expect(wrapper.getByRole('img', { name: /confetti/i })).toBeInTheDocument()
  })
})
