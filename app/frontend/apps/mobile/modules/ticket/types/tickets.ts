// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TicketQuery } from '@shared/graphql/types'
import { ConfidentTake } from '@shared/types/utils'

export type TicketById = TicketQuery['ticket']
export type TicketArticle = ConfidentTake<
  TicketQuery,
  'ticket.articles.edges.node'
>
