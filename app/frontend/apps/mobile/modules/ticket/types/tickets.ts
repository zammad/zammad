// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { TicketQuery, TicketArticlesQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'

export type TicketById = TicketQuery['ticket']
export type TicketArticle = ConfidentTake<
  TicketArticlesQuery,
  'ticketArticles.edges.node'
>

export type TicketArticleAttachment = TicketArticle['attachments'][number]
