// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nullableMock } from '#tests/support/utils.ts'

import { EnumTicketArticleSenderName, type TicketArticlesQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import type { LastArrayElement } from 'type-fest'

export const mockTicketCreateAtDate = new Date(2011, 11, 11, 11, 11, 11, 11)

export const defaultAuthor = {
  __typename: 'User' as const,
  id: '11',
  firstname: 'Author',
  lastname: 'Joe',
  fullname: 'Author Joe',
  email: 'author.joe@example.com',
  active: true,
  image: null,
  vip: false,
  outOfOffice: false,
  outOfOfficeStartAt: null,
  outOfOfficeEndAt: null,
  authorizations: [],
}

export const defaultFromAddress = {
  __typename: 'AddressesField' as const,
  raw: 'Nicole Braun <nicole.braun@zammad.org>',
  parsed: [
    {
      __typename: 'EmailAddressParsed' as const,
      name: 'Nicole Braun',
      emailAddress: 'nicole.braun@zammad.org',
      isSystemAddress: false,
    },
  ],
}

export const defaultBodyWithUrls = '<p>Default test body</p>'

type ArticleNode = LastArrayElement<TicketArticlesQuery['articles']['edges']>['node']
type ArticleNodeOptions = DeepPartial<ArticleNode>

export const createDummyArticle = (options?: {
  articleId?: number
  from?: ArticleNodeOptions['from']
  author?: ArticleNodeOptions['author']
  internal?: ArticleNodeOptions['internal']
  bodyWithUrls?: ArticleNodeOptions['bodyWithUrls']
  to?: ArticleNodeOptions['to']
  cc?: ArticleNodeOptions['cc']
  replyTo?: ArticleNodeOptions['replyTo']
  subject?: ArticleNodeOptions['subject']
  articleType?: string
  attachmentsWithoutInline?: ArticleNodeOptions['attachmentsWithoutInline']
  contentType?: ArticleNodeOptions['contentType']
  securityState?: ArticleNodeOptions['securityState']
  senderName?: EnumTicketArticleSenderName
  mediaErrorState?: ArticleNodeOptions['mediaErrorState']
  preferences?: ArticleNodeOptions['preferences']
  detectedLanguage?: ArticleNodeOptions['detectedLanguage']
  bodyRenderingError?: ArticleNode['bodyRenderingError']
}) => {
  return nullableMock<ArticleNode>({
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
    attachmentsWithoutInline: options?.attachmentsWithoutInline || [],
    preferences: options?.preferences || {},
    bodyWithUrls: options?.bodyWithUrls || defaultBodyWithUrls,
    bodyRenderingError: options?.bodyRenderingError || false,
    internal: !!options?.internal,
    createdAt: mockTicketCreateAtDate.toISOString(),
    author: options?.author === undefined ? defaultAuthor : options?.author,
    type: {
      __typename: 'TicketArticleType',
      name: options?.articleType || 'string',
      communication: false,
    },
    sender: {
      __typename: 'TicketArticleSender',
      name: options?.senderName || EnumTicketArticleSenderName.Customer,
    },
    securityState: options?.securityState === undefined ? null : options.securityState,
    mediaErrorState: options?.mediaErrorState === undefined ? null : options.mediaErrorState,
    detectedLanguage: options?.detectedLanguage ?? null,
  })
}
