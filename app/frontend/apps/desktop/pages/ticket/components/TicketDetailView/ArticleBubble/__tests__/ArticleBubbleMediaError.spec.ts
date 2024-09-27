// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import {
  mockTicketArticleRetryMediaDownloadMutation,
  waitForTicketArticleRetryMediaDownloadMutationCalls,
} from '#shared/entities/ticket-article/graphql/mutations/ticketArticleRetryMediaDownload.mocks.ts'

import ArticleBubbleMediaError from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleMediaError.vue'

const renderArticleBubbleMediaError = (
  article: ReturnType<typeof createDummyArticle>,
) => {
  return renderComponent(
    {
      setup() {
        return { article }
      },
      components: { ArticleBubbleMediaError },
      template: `<div><ArticleBubbleMediaError :article="article" /></div>`,
    },
    { router: true },
  )
}

describe('ArticleBubbleMediaError', () => {
  it('does not display anything if there is no media error', () => {
    const wrapper = renderArticleBubbleMediaError(createDummyArticle())

    expect(wrapper.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('displays a warning in case of a media error', () => {
    const wrapper = renderArticleBubbleMediaError(
      createDummyArticle({
        mediaErrorState: {
          error: true,
        },
      }),
    )

    const warning = wrapper.getByRole('alert')

    expect(getByIconName(warning, 'exclamation-triangle')).toBeInTheDocument()

    expect(
      within(warning).getByText('Failed to load content.'),
    ).toBeInTheDocument()
  })

  it('shows a button to trigger the retry media download process', async () => {
    const testArticle = createDummyArticle({
      mediaErrorState: {
        error: true,
      },
    })

    const wrapper = renderArticleBubbleMediaError(testArticle)

    const warning = wrapper.getByRole('alert')

    expect(getByIconName(warning, 'exclamation-triangle')).toBeInTheDocument()

    mockTicketArticleRetryMediaDownloadMutation({
      ticketArticleRetryMediaDownload: {
        success: true,
      },
    })

    const retryButton = within(warning).getByRole('button', {
      name: 'Retry Attachment Download',
    })

    await wrapper.events.click(retryButton)

    const calls = await waitForTicketArticleRetryMediaDownloadMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      articleId: testArticle.id,
    })
  })
})
