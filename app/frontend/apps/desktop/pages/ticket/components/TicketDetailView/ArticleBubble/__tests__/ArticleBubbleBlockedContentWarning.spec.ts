// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleBubbleBlockedContentWarning from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBlockedContentWarning.vue'

describe('ArticleBubbleBlockedContentWarning', () => {
  it('does not show if there is no blocked content', () => {
    const wrapper = renderComponent(ArticleBubbleBlockedContentWarning, {
      router: true,
      props: {
        article: {},
      },
      setup: () => {
        const ticket = createDummyTicket()
        provideTicketInformationMocks(ticket)
      },
    })
    expect(
      wrapper.queryByIconName('exclamation-triangle'),
    ).not.toBeInTheDocument()
    expect(wrapper.queryByText('Original Formatting')).not.toBeInTheDocument()
  })

  // TODO: still skipped?!
  it.skip('shows if there is blocked content', () => {
    const wrapper = renderComponent(ArticleBubbleBlockedContentWarning, {
      router: true,
      props: {
        article: {
          preferences: {
            remote_content_removed: true,
          },
        },
      },
      setup: () => {
        const ticket = createDummyTicket()

        provideTicketInformationMocks(ticket)
      },
    })
    console.log(wrapper.html())
    expect(wrapper.getByIconName('exclamation-triangle')).toBeInTheDocument()
    expect(wrapper.getByText('Original Formatting')).toBeInTheDocument()
  })
})
