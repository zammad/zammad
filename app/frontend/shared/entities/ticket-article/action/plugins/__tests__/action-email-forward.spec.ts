// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { nullableMock } from '#tests/support/utils.ts'

import type { TicketArticle, TicketById } from '#shared/entities/ticket/types.ts'
import { mockTicketArticleEmailForwardReplyMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleEmailForwardReply.mocks.ts'
import type { TicketArticleEmailForwardReplyMutation } from '#shared/graphql/types.ts'
import type { ConfigList } from '#shared/types/store.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import { buildEmailForwardHeader, forwardEmail } from '../email/forward.ts'

import type { TicketArticlePerformOptions } from '../types.ts'

type ForwardReplyPayload = ConfidentTake<
  TicketArticleEmailForwardReplyMutation,
  'ticketArticleEmailForwardReply'
>

describe('building header, when "forward" action is called', () => {
  it('renders all fields', () => {
    const article = generateObjectData<TicketArticle>('TicketArticle')
    article.subject = 'Article Subject'
    article.createdAt = new Date(2020, 1, 1).toISOString()

    const meta = nullableMock<ForwardReplyPayload>({
      quotableFrom: 'Jhon Doe <jhon.doe@email.dcom>',
      quotableCc: 'Agent Rodrigez',
      quotableTo: 'Agent Smith <smith.a@matrix.com>',
      attachments: [],
    })

    expect(buildEmailForwardHeader(article, meta)).toBe(
      '<p>Subject: Article Subject<br>Date: 2020-02-01 00:00<br>From: Jhon Doe &lt;jhon.doe@email.dcom&gt;<br>To: Agent Smith &lt;smith.a@matrix.com&gt;<br>CC: Agent Rodrigez<br><br></p>',
    )
  })

  it('removes empty fields', () => {
    const article = generateObjectData<TicketArticle>('TicketArticle')
    article.subject = null
    article.createdAt = new Date(2020, 1, 1).toISOString()

    const meta = nullableMock<ForwardReplyPayload>({
      quotableFrom: 'Jhon Doe <jhon.doe@email.dcom>',
      quotableCc: null,
      quotableTo: 'Agent Smith <smith.a@matrix.com>',
      attachments: [],
    })

    expect(buildEmailForwardHeader(article, meta)).toBe(
      '<p>Date: 2020-02-01 00:00<br>From: Jhon Doe &lt;jhon.doe@email.dcom&gt;<br>To: Agent Smith &lt;smith.a@matrix.com&gt;<br><br></p>',
    )
  })
})

describe('forwarding an email article with attachments', () => {
  it('passes the preview links of the original attachments to the reply form', async () => {
    const article = generateObjectData<TicketArticle>('TicketArticle', {
      contentType: 'text/html',
      bodyWithUrls: '<p>Forwarded body</p>',
      attachmentsWithoutInline: [
        {
          name: 'screenshot.png',
          type: 'image/png',
        },
      ],
    })

    mockTicketArticleEmailForwardReplyMutation({
      ticketArticleEmailForwardReply: {
        attachments: [
          {
            name: 'screenshot.png',
            type: 'image/png',
          },
        ],
        errors: null,
      },
    })

    const openReplyForm = vi.fn().mockResolvedValue(undefined)
    const options: TicketArticlePerformOptions = {
      formId: 'ticket-article-forward-form',
      openReplyForm,
      getNewArticleBody: () => '',
    }

    const config = {
      api_path: '/api/v1',
    } as unknown as ConfigList

    mockApplicationConfig({
      'active_storage.content_types_allowed_inline': ['image/png'],
    })

    await forwardEmail(generateObjectData<TicketById>('Ticket'), article, options, config)

    // The links point at the original attachment, not at the one the mutation returned.
    const { internalId } = article.attachmentsWithoutInline[0]

    expect(openReplyForm).toHaveBeenCalledWith(
      expect.objectContaining({
        attachments: [
          expect.objectContaining({
            name: 'screenshot.png',
            preview: `/api/v1/attachments/${internalId}?preview=1`,
            inline: `/api/v1/attachments/${internalId}?disposition=inline`,
          }),
        ],
      }),
    )
  })
})
