// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nullableMock } from '#tests/support/utils.ts'

import {
  EnumTicketArticleSenderName,
  type TicketArticleEdge,
  type TicketArticlesQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import type { LastArrayElement } from 'type-fest'

export const mockTicketDate = new Date(2022, 0, 30, 0, 0, 0, 0)

export const mockAddress = {
  __typename: 'AddressesField' as const,
  parsed: null,
  raw: '',
}

type ArticleNode = NonNullable<LastArrayElement<TicketArticlesQuery['articles']['edges']>>['node']

export const articleContent = (
  id: number,
  mockedArticleData: DeepPartial<ArticleNode>,
): ArticleNode => {
  return nullableMock<ArticleNode>({
    __typename: 'TicketArticle',
    id: convertToGraphQLId('TicketArticle', id),
    internalId: id,
    createdAt: mockTicketDate.toISOString(),
    to: mockAddress,
    replyTo: mockAddress,
    cc: mockAddress,
    from: mockAddress,
    author: {
      __typename: 'User',
      id: 'fdsf214fse12d',
      firstname: 'John',
      lastname: 'Doe',
      fullname: 'John Doe',
      email: 'john.doe@example.com',
      active: true,
      image: null,
      vip: false,
      outOfOffice: false,
      outOfOfficeStartAt: null,
      outOfOfficeEndAt: null,
      authorizations: [],
    },
    internal: false,
    bodyWithUrls: '<p>default body</p>',
    bodyRenderingError: false,
    sender: {
      __typename: 'TicketArticleSender',
      name: EnumTicketArticleSenderName.Customer,
    },
    type: {
      __typename: 'TicketArticleType',
      name: 'article',
      communication: false,
    },
    contentType: 'text/html',
    attachmentsWithoutInline: [],
    preferences: {},
    ...mockedArticleData,
  })
}

export const mockArticleQuery = (
  firstArticles: DeepPartial<ArticleNode>,
  articles: DeepPartial<ArticleNode>[] = [],
  totalCount = articles.length + 1,
): TicketArticlesQuery => {
  const articleNodes = articles.map((article, index) => {
    return nullableMock<TicketArticleEdge>({
      __typename: 'TicketArticleEdge',
      node: articleContent(article.internalId ?? index + 1, article),
      cursor: `MI${index}`,
    })
  })

  return nullableMock<TicketArticlesQuery>({
    firstArticles: {
      __typename: 'TicketArticleConnection',
      edges: [
        {
          __typename: 'TicketArticleEdge',
          node: articleContent(firstArticles.internalId ?? 1, firstArticles),
        },
      ],
    },
    articles: {
      __typename: 'TicketArticleConnection',
      totalCount,
      edges: articleNodes,
      pageInfo: {
        __typename: 'PageInfo',
        hasPreviousPage: false,
        startCursor: articleNodes[0]?.cursor ?? '',
      },
    },
  })
}
