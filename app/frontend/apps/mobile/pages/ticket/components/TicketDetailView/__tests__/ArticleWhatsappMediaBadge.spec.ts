// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { mockTicketArticleRetryMediaDownloadMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleRetryMediaDownload.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ArticleWhatsappMediaBadge, {
  type Props,
} from '../ArticleWhatsappMediaBadge.vue'

const renderBadge = (propsData: Props) => {
  return renderComponent(ArticleWhatsappMediaBadge, {
    props: propsData,
  })
}

describe('rendering media error badge for Whatsapp', () => {
  it('renders media error badge', async () => {
    const view = renderBadge({
      articleId: convertToGraphQLId('Ticket::Article', 1),
      mediaError: true,
    })

    expect(view.getByIconName('update')).toBeInTheDocument()
    expect(view.getByText('Media Download Error')).toBeInTheDocument()

    await view.events.click(view.getByRole('button'))

    expect(view.getByText('Try again')).toBeInTheDocument()

    mockTicketArticleRetryMediaDownloadMutation({
      ticketArticleRetryMediaDownload: {
        success: true,
      },
    })

    await view.events.click(view.getByText('Try again'))

    expect(
      view.queryByRole('button', { name: 'Try again' }),
    ).not.toBeInTheDocument()
  })

  it('renders no media error badge if download was fine', async () => {
    const view = renderBadge({
      articleId: convertToGraphQLId('Ticket::Article', 1),
      mediaError: false,
    })

    expect(view.queryByIconName('update')).not.toBeInTheDocument()
    expect(
      view.queryByRole('button', { name: 'Media Download Error' }),
    ).not.toBeInTheDocument()
  })
})
