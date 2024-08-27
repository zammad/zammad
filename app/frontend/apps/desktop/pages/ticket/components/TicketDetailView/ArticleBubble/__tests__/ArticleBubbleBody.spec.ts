// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { provideLocal } from '@vueuse/shared'
import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import ArticleBubbleBody from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBody.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const renderBody = (
  article: ReturnType<typeof createDummyArticle>,
  showMetaInformation: boolean,
) => {
  return renderComponent(
    {
      components: { ArticleBubbleBody },

      setup: () => {
        const dummyTicket = createDummyTicket()

        provideLocal(TICKET_KEY, {
          ticketId: computed(() => dummyTicket.id),
          ticket: computed(() => dummyTicket),
          ticketInternalId: ref(dummyTicket.internalId),
        })
        return {
          article,
          showMetaInformation,
        }
      },
      template:
        '<ArticleBubbleBody :article="article" :showMetaInformation="showMetaInformation" position="left" :inlineImages="[]"/>',
    },
    {
      router: true,
      store: true,
    },
  )
}

describe('ArticleBubbleBody', () => {
  it('displays html article body with meta information display active', async () => {
    const article = createDummyArticle({
      bodyWithUrls: 'test &amp; body',
      contentType: 'text/html',
    })

    const wrapper = renderBody(article, true)
    expect(await wrapper.findByText('test & body')).toBeInTheDocument()
    expect(
      await wrapper.queryByText(article.author.fullname!),
    ).not.toBeInTheDocument()
  })

  it('displays text article body with meta information display inactive', async () => {
    const article = createDummyArticle({
      bodyWithUrls: 'test &amp; body',
      contentType: 'text/plain',
    })

    const wrapper = renderBody(article, false)
    expect(await wrapper.findByText('test &amp; body')).toBeInTheDocument()
    expect(
      await wrapper.queryByText(article.author.fullname!),
    ).to.toBeInTheDocument()
  })
})
