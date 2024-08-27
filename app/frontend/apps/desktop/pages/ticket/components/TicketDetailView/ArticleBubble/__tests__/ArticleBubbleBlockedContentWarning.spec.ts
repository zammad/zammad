// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { provideLocal } from '@vueuse/shared'
import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import ArticleBubbleBlockedContentWarning from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBlockedContentWarning.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

describe('ArticleBubbleBlockedContentWarning', () => {
  it('does not show if there is no blocked content', () => {
    const wrapper = renderComponent(ArticleBubbleBlockedContentWarning, {
      router: true,
      props: {
        article: {},
      },
      setup: () => {
        const ticket = createDummyTicket()
        provideLocal(TICKET_KEY, {
          ticket: computed(() => ticket),
          ticketId: computed(() => ticket.id),
          ticketInternalId: ref(ticket.internalId),
        })
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
        provideLocal(TICKET_KEY, {
          ticket: computed(() => ticket),
          ticketId: computed(() => ticket.id),
          ticketInternalId: ref(ticket.internalId),
        })
      },
    })
    console.log(wrapper.html())
    expect(wrapper.getByIconName('exclamation-triangle')).toBeInTheDocument()
    expect(wrapper.getByText('Original Formatting')).toBeInTheDocument()
  })
})
