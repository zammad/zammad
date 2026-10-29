// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { nullableMock } from '#tests/support/utils.ts'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { defaultTicket } from '#mobile/pages/ticket/__tests__/mocks/detail-view.ts'
import { TICKET_INFORMATION_SYMBOL } from '#mobile/pages/ticket/composable/useTicketInformation.ts'

import ArticlesList from '../ArticlesList.vue'

vi.mock('#shared/utils/openExternalLink.ts', async () => ({
  default: vi.fn(),
}))

const { default: openExternalLinkMock } = await import('#shared/utils/openExternalLink.ts')

it('renders delivery messages', () => {
  const { ticket } = defaultTicket()
  const articles: TicketArticle[] = [
    nullableMock<TicketArticle>({
      __typename: 'TicketArticle',
      id: convertToGraphQLId('TicketArticle', 1),
      internal: false,
      internalId: 1,
      contentType: 'text/html',
      bodyWithUrls:
        "Unable to send tweet: Can't find ticket.preferences[channel_id'] for Ticket.find(2)",
      createdAt: '2021-09-01T12:00:00.000Z',
      preferences: {
        delivery_message: true,
      },
      attachmentsWithoutInline: [],
      bodyRenderingError: false,
      author: {
        __typename: 'User',
        id: convertToGraphQLId('User', 1),
      },
    }),
  ]

  const view = renderComponent(ArticlesList, {
    props: {
      ticket,
      articles,
      totalCount: 1,
    },
    provide: [[TICKET_INFORMATION_SYMBOL, {}]],
  })

  expect(view.container).toHaveTextContent('Delivery failed')
  expect(view.container).toHaveTextContent(articles[0].bodyWithUrls)
  expect(view.getByIconName('warning')).toBeInTheDocument()
})

it('renders the warning of an unprocessable email in place of the flagged article', async () => {
  mockApplicationConfig({ api_path: '/api' })

  const { ticket } = defaultTicket()
  const articles: TicketArticle[] = [
    nullableMock<TicketArticle>({
      __typename: 'TicketArticle',
      id: convertToGraphQLId('TicketArticle', 1),
      internal: true,
      internalId: 1,
      contentType: 'text/plain',
      bodyWithUrls:
        'This ticket was created because the email could not be processed. The original email and the processing log are attached.',
      createdAt: '2021-09-01T12:00:00.000Z',
      preferences: {
        email_unprocessable: true,
      },
      attachmentsWithoutInline: [
        {
          __typename: 'StoredFile',
          id: convertToGraphQLId('Store', 41),
          internalId: 41,
          name: 'unprocessable_email.eml',
          type: 'message/rfc822',
          size: 100,
          preferences: { email_unprocessable: 'raw' },
        },
        {
          __typename: 'StoredFile',
          id: convertToGraphQLId('Store', 42),
          internalId: 42,
          name: 'processing_log.txt',
          type: 'text/plain',
          size: 100,
          preferences: { email_unprocessable: 'log' },
        },
      ],
      bodyRenderingError: false,
      author: {
        __typename: 'User',
        id: convertToGraphQLId('User', 1),
      },
    }),
  ]

  const view = renderComponent(ArticlesList, {
    props: {
      ticket,
      articles,
      totalCount: 1,
    },
    provide: [[TICKET_INFORMATION_SYMBOL, {}]],
    router: true,
  })

  const alert = view.getByRole('alert')

  expect(alert).toHaveAttribute('id', 'article-1')
  expect(alert).toHaveClasses(['border-yellow', 'bg-yellow-highlight', 'text-yellow'])
  expect(view.getByRole('button', { name: 'Download raw email' })).toHaveClass('bg-yellow')
  expect(alert).toHaveTextContent(
    'This ticket was created because the email could not be processed. Download the raw email to see what was received, and the processing log to see why processing failed.',
  )
  expect(view.container.querySelector('section')?.firstElementChild).toBe(alert)

  expect(view.queryByRole('comment')).not.toBeInTheDocument()
  expect(view.container).not.toHaveTextContent(
    'The original email and the processing log are attached.',
  )

  await view.events.click(view.getByRole('button', { name: 'Download raw email' }))

  expect(openExternalLinkMock).toHaveBeenLastCalledWith(
    '/api/attachments/41?disposition=attachment',
    '_blank',
    'unprocessable_email.eml',
  )

  await view.events.click(view.getByRole('button', { name: 'Download processing log' }))

  expect(openExternalLinkMock).toHaveBeenLastCalledWith(
    '/api/attachments/42?disposition=attachment',
    '_blank',
    'processing_log.txt',
  )
})
