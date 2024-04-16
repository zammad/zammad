// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchAgentQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type AutoCompleteAgentOption = ConfidentTake<
  AutocompleteSearchAgentQuery,
  'autocompleteSearchAgent'
>[number]
