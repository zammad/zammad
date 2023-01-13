// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultArticles } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import { initializeStore } from '@tests/support/components/initializeStore'
import { createArticleActions, createArticleTypes } from '../index'
import type { CommonTicketActionAddOptions } from '../types'

export const createTicketArticle = () => {
  const { description } = defaultArticles()
  return description.edges[0].node
}

const defaultOptions: Pick<
  CommonTicketActionAddOptions,
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
  return createArticleActions(ticket, article, options)
}

export const createTestArticleTypes = (
  ticket: TicketById,
  options = defaultOptions,
) => {
  initializeStore()
  return createArticleTypes(ticket, options)
}
