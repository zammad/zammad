// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchTicketQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type AutoCompleteTicketOption = ConfidentTake<
  AutocompleteSearchTicketQuery,
  'autocompleteSearchTicket'
>[number]
