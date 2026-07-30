// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import { EnumTicketArticleSenderName, type TicketArticle } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<TicketArticle> => {
  const senderNumber = faker.number.int({ min: 0, max: 2 })
  const body = faker.lorem.paragraph()
  return {
    contentType: faker.helpers.arrayElement(['text/html', 'text/plain']),
    body,
    bodyWithUrls: body,
    // Default both attachment lists to empty: the mocker generates every schema field of the
    // type, not just the queried ones, so leaving `attachments` out made each generated article
    // roll 1-5 random StoredFiles for it. Tests with many articles could then exceed the
    // mocker's 100-generated-ids-per-type loop guard.
    attachments: [],
    attachmentsWithoutInline: [],
    sender: {
      id: convertToGraphQLId('TicketArticleSender', senderNumber + 1),
      name: [
        EnumTicketArticleSenderName.Agent,
        EnumTicketArticleSenderName.Customer,
        EnumTicketArticleSenderName.System,
      ][senderNumber],
    },
    // possible types: db/seeds/ticket_article_types.rb
    // we only generate emails to have consistent articles
    type: {
      __typename: 'TicketArticleType',
      id: convertToGraphQLId('TicketArticleType', 1),
      name: 'email',
      communication: false,
    },
  }
}
