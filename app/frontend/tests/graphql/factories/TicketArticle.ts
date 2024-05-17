// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { TicketArticle } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<TicketArticle> => {
  const senderNumber = faker.number.int({ min: 0, max: 2 })
  const body = faker.lorem.paragraph()
  return {
    contentType: faker.helpers.arrayElement(['text/html', 'text/plain']),
    body,
    bodyWithUrls: body,
    attachmentsWithoutInline: [],
    sender: {
      id: convertToGraphQLId('TicketArticleSender', senderNumber + 1),
      name: ['Agent', 'Customer', 'System'][senderNumber],
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
