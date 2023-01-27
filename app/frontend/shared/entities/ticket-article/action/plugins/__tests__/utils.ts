// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  defaultArticles,
  defaultTicket,
} from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import type { AppName } from '@shared/types/app'
import { initializeStore } from '@tests/support/components/initializeStore'
import { createArticleActions, createArticleTypes } from '../index'
import type { TicketActionAddOptions } from '../types'

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

export const createEligibleTicketArticleReplyData = (type: string) => {
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
  const { ticket } = defaultTicket()
  ticket.policy.update = true
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
