// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '#shared/components/Form/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useTicketSharedDraft } from '../useTicketSharedDraft.ts'

describe('useTicketSharedDraft', () => {
  const ticketId = convertToGraphQLId('Ticket', 1)

  const formWith = (article?: Record<string, unknown>) =>
    ({
      formId: 'form-id',
      values: { title: 'Welcome', ...(article && { article }) },
    }) as unknown as FormRef

  it('maps the article of the form to the draft', () => {
    const { mapSharedDraftParams } = useTicketSharedDraft()

    expect(
      mapSharedDraftParams(
        ticketId,
        formWith({
          articleType: 'email',
          to: ['nicole.braun@zammad.org', 'support@zammad.org'],
          cc: [],
          body: 'Hello',
        }),
      ),
    ).toEqual({
      ticketId,
      formId: 'form-id',
      ticketAttributes: { title: 'Welcome' },
      newArticle: {
        articleType: 'email',
        type: 'email',
        to: 'nicole.braun@zammad.org, support@zammad.org',
        cc: '',
        body: 'Hello',
      },
    })
  })

  it('keeps the answered article out of the draft, and in the form', () => {
    const { mapSharedDraftParams } = useTicketSharedDraft()

    const article = {
      articleType: 'email',
      answeredArticleId: convertToGraphQLId('TicketArticle', 1),
      to: ['nicole.braun@zammad.org'],
      body: 'Hello',
    }

    const { newArticle } = mapSharedDraftParams(ticketId, formWith(article))

    expect(newArticle).not.toHaveProperty('answeredArticleId')
    expect(article).toEqual({
      articleType: 'email',
      answeredArticleId: convertToGraphQLId('TicketArticle', 1),
      to: ['nicole.braun@zammad.org'],
      body: 'Hello',
    })
  })

  it('maps a form without an article to an empty draft article', () => {
    const { mapSharedDraftParams } = useTicketSharedDraft()

    expect(mapSharedDraftParams(ticketId, formWith()).newArticle).toEqual({})
  })
})
