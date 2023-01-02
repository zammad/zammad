// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultArticles } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import type { TicketArticle } from '@mobile/pages/ticket/types/tickets'
import { getAllByRole } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'
import ArticleMetadata from '../ArticleMetadataDialog.vue'

// parsed is tested in unit test
const getAddress = (raw: string) => ({
  raw,
  parsed: null,
})

describe('visuals for metadata', () => {
  it('renders article metadata', () => {
    const createdAt = new Date(2022, 1, 1, 0, 0, 0, 0).toISOString()

    const article: TicketArticle = {
      // default article has attachment that should be visible as a link
      ...defaultArticles().description.edges[0].node,
      internalId: 1,
      from: getAddress(
        '"Test Admin Agent via Zammad Helpdesk" <zammad@localhost>',
      ),
      to: getAddress('Nicole Braun <nicole.braun@zammad.org>'),
      subject: 'Some Email',
      cc: getAddress('Joe Mike <joe.mike@zammad.org>'),
      replyTo: getAddress('Arthur Miller <arthur.miller@zammad.org>'),
      type: {
        name: 'email',
      },
      createdAt,
      preferences: {
        links: [
          {
            label: 'Twitter',
            url: 'https://twitter.com/zammad',
            target: '_blank',
          },
        ],
      },
    }

    const view = renderComponent(ArticleMetadata, {
      props: {
        name: 'article',
        article,
        ticketInternalId: 2,
      },
      router: true,
      store: true,
    })

    expect(view.getByRole('region', { name: 'From' })).toHaveTextContent(
      /Test Admin Agent via Zammad Helpdesk/,
    )
    expect(view.getByRole('region', { name: 'To' })).toHaveTextContent(
      /Nicole Braun <nicole.braun@zammad.org>/,
    )
    expect(view.getByRole('region', { name: 'Subject' })).toHaveTextContent(
      /Some Email/,
    )
    expect(view.getByRole('region', { name: 'CC' })).toHaveTextContent(
      /Joe Mike <joe.mike@zammad.org>/,
    )
    expect(view.getByRole('region', { name: 'Reply-To' })).toHaveTextContent(
      /Arthur Miller <arthur.miller@zammad.org/,
    )
    expect(view.getByRole('region', { name: 'Sent' })).toHaveTextContent(
      /2022-02-01 00:00$/,
    )
    const channel = view.getByRole('region', { name: 'Channel' })
    expect(channel).toHaveTextContent(/email/)
    expect(view.getByIconName('mobile-mail')).toBeInTheDocument()
    const links = getAllByRole(channel, 'link')
    expect(links).toHaveLength(3)

    const [twitter, raw, attachment] = links

    expect(twitter).toHaveTextContent('Twitter')
    expect(twitter).toHaveAttribute('href', 'https://twitter.com/zammad')

    expect(raw).toHaveTextContent('Raw')
    expect(raw).toHaveAttribute('href', '/api/ticket_article_plain/1')

    expect(attachment).toHaveTextContent('Original Formatting')
    expect(attachment).toHaveAttribute(
      'href',
      '/api/ticket_attachment/2/1/66?disposition=attachment',
    )
  })
})
