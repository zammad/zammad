// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'

import type { TicketArticle } from '#shared/graphql/types.ts'

import { buildEmailForwardHeader } from '../email/forward.ts'

describe('building header, when "forward" action is called', () => {
  it('renders all fields', () => {
    const article = generateObjectData<TicketArticle>('TicketArticle')
    article.subject = 'Article Subject'
    article.createdAt = new Date(2020, 1, 1).toISOString()

    const meta = {
      quotableFrom: 'Jhon Doe <jhon.doe@email.dcom>',
      quotableCc: 'Agent Rodrigez',
      quotableTo: 'Agent Smith <smith.a@matrix.com>',
      attachments: [],
    }

    expect(buildEmailForwardHeader(article, meta)).toBe(
      '<p>Subject: Article Subject<br>Date: 2020-02-01 00:00<br>From: Jhon Doe &lt;jhon.doe@email.dcom&gt;<br>To: Agent Smith &lt;smith.a@matrix.com&gt;<br>CC: Agent Rodrigez<br><br></p>',
    )
  })

  it('removes empty fields', () => {
    const article = generateObjectData<TicketArticle>('TicketArticle')
    article.subject = null
    article.createdAt = new Date(2020, 1, 1).toISOString()

    const meta = {
      quotableFrom: 'Jhon Doe <jhon.doe@email.dcom>',
      quotableCc: null,
      quotableTo: 'Agent Smith <smith.a@matrix.com>',
      attachments: [],
    }

    expect(buildEmailForwardHeader(article, meta)).toBe(
      '<p>Date: 2020-02-01 00:00<br>From: Jhon Doe &lt;jhon.doe@email.dcom&gt;<br>To: Agent Smith &lt;smith.a@matrix.com&gt;<br><br></p>',
    )
  })
})
