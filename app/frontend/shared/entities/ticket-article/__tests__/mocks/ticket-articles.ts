// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { nullableMock } from '#tests/support/utils.ts'

import {
  EnumTicketArticleSenderName,
  type TicketArticlesQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { LastArrayElement } from 'type-fest'

export const mockTicketCreateAtDate = new Date(2011, 11, 11, 11, 11, 11, 11)

export const defaultAuthor = {
  __typename: 'User',
  id: '11',
  firstname: 'Author',
  lastname: 'Joe',
  fullname: 'Author Joe',
  active: true,
  image: null,
  authorizations: [],
}

export const defaultFromAddress = {
  __typename: 'AddressesField',
  raw: 'Nicole Braun <nicole.braun@zammad.org>',
  parsed: [
    {
      __typename: 'EmailAddressParsed',
      name: 'Nicole Braun',
      emailAddress: 'nicole.braun@zammad.org',
      isSystemAddress: false,
    },
  ],
}

export const defaultBodyWithUrls = '<p>Default test body</p>'

type ArticleNode = LastArrayElement<
  TicketArticlesQuery['articles']['edges']
>['node']

export const createDummyArticle = (options?: {
  articleId?: number
  from?: ArticleNode['from']
  author?: ArticleNode['author']
  internal?: ArticleNode['internal']
  bodyWithUrls?: ArticleNode['bodyWithUrls']
  to?: ArticleNode['to']
  cc?: ArticleNode['cc']
  replyTo?: ArticleNode['replyTo']
  subject?: ArticleNode['subject']
  articleType?: string
  attachmentsWithoutInline?: ArticleNode['attachmentsWithoutInline']
  contentType?: ArticleNode['contentType']
  securityState?: ArticleNode['securityState']
  senderName?: EnumTicketArticleSenderName
  mediaErrorState?: ArticleNode['mediaErrorState']
  preferences?: ArticleNode['preferences']
  // eslint-disable-next-line sonarjs/cognitive-complexity
}) => {
  return nullableMock({
    __typename: 'TicketArticle',
    id: convertToGraphQLId('TicketArticle', options?.articleId || 1),
    internalId: options?.articleId || 1,
    from: options?.from === undefined ? defaultFromAddress : options?.from,
    messageId: null,
    to: options?.to === undefined ? null : options?.to,
    cc: options?.cc === undefined ? null : options?.cc,
    subject: options?.subject === undefined ? null : options?.subject,
    replyTo: options?.replyTo || null,
    messageIdMd5: null,
    contentType: options?.contentType || 'text/plain',
    references: null,
    attachmentsWithoutInline: options?.attachmentsWithoutInline || [],
    preferences: options?.preferences || {},
    bodyWithUrls: options?.bodyWithUrls || defaultBodyWithUrls,
    internal: !!options?.internal,
    createdAt: mockTicketCreateAtDate.toISOString(),
    author: options?.author === undefined ? defaultAuthor : options?.author,
    type: {
      __typename: 'TicketArticleType',
      name: options?.articleType || 'string',
    },
    sender: {
      __typename: 'TicketArticleSender',
      name: options?.senderName || EnumTicketArticleSenderName.Customer,
    },
    securityState:
      options?.securityState === undefined ? null : options.securityState,
    mediaErrorState:
      options?.mediaErrorState === undefined ? null : options.mediaErrorState,
  }) as ArticleNode
}
