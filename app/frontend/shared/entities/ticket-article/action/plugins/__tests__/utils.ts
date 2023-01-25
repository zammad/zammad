// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultArticles } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
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
