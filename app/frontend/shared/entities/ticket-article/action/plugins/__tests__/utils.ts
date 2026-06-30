// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { initializeStore } from '#tests/support/components/initializeStore.ts'

import type { TicketArticle, TicketById } from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName, type PolicyTicket } from '#shared/graphql/types.ts'
import type { AppName } from '#shared/types/app.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { createArticleActions, createArticleTypes } from '../index.ts'

import type { TicketActionAddOptions } from '../types.ts'

type TestTicketArticle = DeepPartial<TicketArticle> & Pick<TicketArticle, 'id' | 'internalId'>

export const createTicketArticle = (defaults?: DeepPartial<TicketArticle>): TestTicketArticle => {
  return generateObjectData<TicketArticle>('TicketArticle', defaults) as TestTicketArticle
}

const defaultOptions: Pick<TicketActionAddOptions, 'onDispose' | 'recalculate'> = {
  recalculate: vi.fn(),
  onDispose: vi.fn(),
}

export const createTicket = (defaults?: DeepPartial<TicketById>): TicketById =>
  generateObjectData<TicketById>('Ticket', defaults)

export const createEligibleTicketArticleReplyData = (
  type: string,
  policies: Partial<PolicyTicket> = {},
) => {
  const article = createTicketArticle({
    sender: { name: EnumTicketArticleSenderName.Customer },
    type: {
      name: type,
      communication: false,
    },
  })
  const ticket = createTicket({ policy: { update: true, ...policies } })
  return {
    article,
    ticket,
  }
}

export const createTestArticleActions = (
  ticket: TicketById,
  article: TestTicketArticle,
  app: AppName = 'mobile',
) => {
  initializeStore()
  return createArticleActions(ticket, article as TicketArticle, app, defaultOptions)
}

export const createTestArticleTypes = (ticket: TicketById, app: AppName = 'mobile') => {
  initializeStore()
  return createArticleTypes(ticket as TicketById, app)
}
