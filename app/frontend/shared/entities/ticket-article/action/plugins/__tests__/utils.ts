// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { initializeStore } from '#tests/support/components/initializeStore.ts'

import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import type { PolicyTicket, Ticket } from '#shared/graphql/types.ts'
import type { AppName } from '#shared/types/app.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { createArticleActions, createArticleTypes } from '../index.ts'

import type { TicketActionAddOptions } from '../types.ts'

export const createTicketArticle = (defaults?: DeepPartial<TicketArticle>) => {
  return generateObjectData<TicketArticle>('TicketArticle', defaults)
}

const defaultOptions: Pick<
  TicketActionAddOptions,
  'onDispose' | 'recalculate'
> = {
  recalculate: vi.fn(),
  onDispose: vi.fn(),
}

export const createTicket = (defaults?: DeepPartial<Ticket>) =>
  generateObjectData<Ticket>('Ticket', defaults)

export const createEligibleTicketArticleReplyData = (
  type: string,
  policies: Partial<PolicyTicket> = {},
) => {
  const article = createTicketArticle({
    sender: { name: 'Customer' },
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
