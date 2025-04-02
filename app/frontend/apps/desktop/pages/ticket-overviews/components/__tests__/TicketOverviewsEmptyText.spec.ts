// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import TicketOverviewsEmptyText from '#desktop/pages/ticket-overviews/components/TicketOverviewsEmptyText.vue'

describe('TicketOverviewsEmptyText', () => {
  it('renders empty text', () => {
    const wrapper = renderComponent(TicketOverviewsEmptyText, {
      props: {
        title: 'No tickets found',
        text: 'Nothing to golden to find in this overview.',
      },
    })

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent(
      'No tickets found',
    )

    expect(
      wrapper.getByText('Nothing to golden to find in this overview.'),
    ).toBeInTheDocument()
  })
})
