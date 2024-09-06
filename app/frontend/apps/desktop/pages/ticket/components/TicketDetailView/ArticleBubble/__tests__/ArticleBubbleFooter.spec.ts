// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleBubbleFooter from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleFooter.vue'

describe('ArticleBubbleFooter', () => {
  it('does not display for articles without attachments', () => {
    const wrapper = renderComponent({
      components: { ArticleBubbleFooter },
      router: true,
      setup: () => {
        const ticket = createDummyTicket()
        provideTicketInformationMocks(ticket)

        return {
          article: createDummyArticle(),
          articleAttachments: [],
        }
      },
      template: `<ArticleBubbleFooter :article-attachments="articleAttachments" :article="article" />`,
    })

    expect(wrapper.baseElement.querySelector('footer')).toBeNull()
  })

  it('displays for articles with attachments', () => {
    const wrapper = renderComponent(
      {
        components: { ArticleBubbleFooter },
        setup: () => {
          const ticket = createDummyTicket()
          provideTicketInformationMocks(ticket)

          return {
            article: createDummyArticle({
              attachmentsWithoutInline: [
                {
                  id: convertToGraphQLId('Store', 123),
                  internalId: 123,
                  name: 'test.txt',
                },
              ],
            }),
            articleAttachments: [
              {
                preview: 'http://test/attachments/123/preview',
                inline: 'http://test/attachments/123/inline',
                canDownload: true,
                name: 'test.txt',
                downloadUrl: 'http://test/attachments/123/download',
              },
            ],
          }
        },
        template: `<ArticleBubbleFooter :article-attachments="articleAttachments" :article="article" />`,
      },
      {
        router: true,
      },
    )

    expect(wrapper.html()).toContain('1 attached file')
    expect(wrapper.html()).toContain('test.txt')
  })
})
