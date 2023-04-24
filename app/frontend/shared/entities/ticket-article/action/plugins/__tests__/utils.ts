// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  defaultArticles,
  defaultTicket,
} from '#mobile/pages/ticket/__tests__/mocks/detail-view.ts'
import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import type { PolicyTicket } from '#shared/graphql/types.ts'
import type { AppName } from '#shared/types/app.ts'
import { initializeStore } from '#tests/support/components/initializeStore.ts'
import { createArticleActions, createArticleTypes } from '../index.ts'
import type { TicketActionAddOptions } from '../types.ts'

export const createTicketArticle = () => {
  const { description } = defaultArticles()
  return description.edges[0].node
}

const defaultOptions: Pick<
  TicketActionAddOptions,
  'onDispose' | 'recalculate'
> = {
  recalculate: vi.fn(),
  onDispose: vi.fn(),
}

export const createEligibleTicketArticleReplyData = (
  type: string,
  policies: Partial<PolicyTicket> = {},
) => {
  const article = createTicketArticle()
  article.sender = {
    name: 'Customer',
    __typename: 'TicketArticleSender',
  }
  article.type = {
    name: type,
    communication: false,
    __typename: 'TicketArticleType',
  }
  const { ticket } = defaultTicket({ update: true, ...policies })
  return {
    article,
    ticket,
  }
}

export const createTestArticleActions = (
  ticket: TicketById,
  article: TicketArticle,
  options = defaultOptions,
) => {
  initializeStore()
  return createArticleActions(ticket, article, 'mobile', options)
}

export const createTestArticleTypes = (
  ticket: TicketById,
  app: AppName = 'mobile',
) => {
  initializeStore()
  return createArticleTypes(ticket, app)
}
