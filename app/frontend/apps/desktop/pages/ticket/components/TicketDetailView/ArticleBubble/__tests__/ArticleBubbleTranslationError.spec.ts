// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { createArticleTranslationMock } from '#shared/entities/ticket-article/__tests__/mocks/articleTranslation.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { TicketArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleBubbleTranslationError from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleTranslationError.vue'

const renderError = (translationFor: TicketArticleTranslation['translationFor']) => {
  const article = createDummyArticle()

  return renderComponent(
    {
      components: { ArticleBubbleTranslationError },
      setup() {
        provideTicketInformationMocks(createDummyTicket(), {
          articleTranslation: createArticleTranslationMock({ translationFor }),
        })

        return { article }
      },
      template: '<ArticleBubbleTranslationError :article="article" />',
    },
    { router: true, store: true },
  )
}

describe('ArticleBubbleTranslationError', () => {
  it('renders nothing without a failed translation', () => {
    const wrapper = renderError(() => ({ status: 'done', content: 'x', translated: true }))

    expect(wrapper.queryByText('Failed to translate article content.')).not.toBeInTheDocument()
  })

  it('names the failure and points to the administrator, without a retry', () => {
    const wrapper = renderError(() => ({ status: 'error', error: 'Provider down' }))

    expect(wrapper.getByRole('alert')).toHaveTextContent(
      'Failed to translate article content. Please contact your administrator.',
    )
    expect(wrapper.getByText('Provider down')).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: /retry/i })).not.toBeInTheDocument()
  })
})
