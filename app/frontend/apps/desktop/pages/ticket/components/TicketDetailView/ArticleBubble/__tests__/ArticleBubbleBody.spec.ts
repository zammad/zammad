// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

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
    expect(await wrapper.queryByText(article.author.fullname!)).not.toBeInTheDocument()
  })

  it('displays text article body with meta information display inactive', async () => {
    const article = createDummyArticle({
      bodyWithUrls: 'test &amp; body',
      contentType: 'text/plain',
    })

    const wrapper = renderBody(article, false)
    expect(await wrapper.findByText('test &amp; body')).toBeInTheDocument()
    expect(await wrapper.queryByText(article.author.fullname!)).to.toBeInTheDocument()
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

  describe('highlight a11y (aria-details)', () => {
    it('adds no aria-details when the article has no highlights', async () => {
      const article = createDummyArticle({
        bodyWithUrls: 'Hello world',
        contentType: 'text/html',
      })

      const wrapper = renderBody(article, false)
      await nextTick()

      expect(
        wrapper.getByTestId('article-content').querySelector('.inner-article-body'),
      ).not.toHaveAttribute('aria-details')
    })

    it('adds aria-details pointing to a hidden description when highlights are present', async () => {
      const article = {
        ...createDummyArticle({
          bodyWithUrls: 'Hello world',
          contentType: 'text/html',
        }),
        highlightedTexts: [
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 0,
            endIndex: 5,
            colorClass: 'highlight-yellow',
          },
        ],
      }

      const wrapper = renderBody(article, false)
      await nextTick()

      const articleBody = wrapper
        .getByTestId('article-content')
        .querySelector('.inner-article-body')!
      const descriptionId = articleBody.getAttribute('aria-details')

      expect(descriptionId).toBeTruthy()

      const descriptionEl = wrapper.container.querySelector(`#${descriptionId}`)
      expect(descriptionEl).toBeInTheDocument()
      expect(descriptionEl).toHaveClass('sr-only')
      expect(descriptionEl?.textContent?.trim()).toContain('Highlighted text')
      expect(descriptionEl?.textContent?.trim()).toContain('Yellow')
      expect(descriptionEl?.textContent?.trim()).toContain('"Hello"')
    })

    it('groups multiple highlights by color in the description', async () => {
      const article = {
        ...createDummyArticle({
          bodyWithUrls: 'Hello world foo',
          contentType: 'text/html',
        }),
        highlightedTexts: [
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 0,
            endIndex: 5,
            colorClass: 'highlight-yellow',
          },
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 6,
            endIndex: 11,
            colorClass: 'highlight-green',
          },
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 12,
            endIndex: 15,
            colorClass: 'highlight-yellow',
          },
        ],
      }

      const wrapper = renderBody(article, false)
      await nextTick()

      const articleBody = wrapper
        .getByTestId('article-content')
        .querySelector('.inner-article-body')!
      const descriptionId = articleBody.getAttribute('aria-details')!
      const descriptionEl = wrapper.container.querySelector(`#${descriptionId}`)!
      const text = descriptionEl.textContent?.trim() ?? ''

      expect(text).toContain('Yellow')
      expect(text).toContain('"Hello"')
      expect(text).toContain('"foo"')
      expect(text).toContain('Green')
      expect(text).toContain('"world"')
    })

    it('removes aria-details and description when all highlights are cleared', async () => {
      const baseArticle = createDummyArticle({
        bodyWithUrls: 'Hello world',
        contentType: 'text/html',
      })

      const article = {
        ...baseArticle,
        highlightedTexts: [
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 0,
            endIndex: 5,
            colorClass: 'highlight-yellow',
          },
        ],
      }

      const wrapper = renderBody(article, false)
      await nextTick()

      // Confirm description is present initially.
      const articleBody = wrapper
        .getByTestId('article-content')
        .querySelector('.inner-article-body')!
      expect(articleBody).toHaveAttribute('aria-details')

      // Clear highlights by re-rendering with null.
      await wrapper.rerender({ article: { ...baseArticle, highlightedTexts: null } })
      await nextTick()

      expect(articleBody).not.toHaveAttribute('aria-details')
      expect(
        wrapper.container.querySelector('[id^="article-highlight-description-"]'),
      ).not.toBeInTheDocument()
    })
  })
})
