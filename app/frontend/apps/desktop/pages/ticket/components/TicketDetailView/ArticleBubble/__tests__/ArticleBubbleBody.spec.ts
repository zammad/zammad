// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleBubbleBody from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBody.vue'

const renderBody = (
  article: ReturnType<typeof createDummyArticle>,
  showMetaInformation: boolean,
) => {
  return renderComponent(
    {
      components: { ArticleBubbleBody },

      setup: () => {
        const dummyTicket = createDummyTicket()

        provideTicketInformationMocks(dummyTicket)

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

  it('does not display system message name on article body', async () => {
    const article = createDummyArticle({
      bodyWithUrls: 'test &amp; body',
      contentType: 'text/plain',
      internal: true,
      author: {
        id: convertToGraphQLId('User', 1), // System message user id
        fullname: '-',
        firstname: '-',
        lastname: '',
        email: '',
        active: false,
        image: null,
        vip: false,
        outOfOffice: false,
        outOfOfficeStartAt: null,
        outOfOfficeEndAt: null,
        authorizations: [],
      },
    })

    const wrapper = renderBody(article, false)

    expect(
      wrapper.queryByRole('group', {
        description: 'Author name and article creation date',
      }),
    ).not.toBeInTheDocument()
  })
})
