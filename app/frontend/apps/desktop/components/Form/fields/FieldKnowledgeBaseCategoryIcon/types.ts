// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchKnowledgeBaseCategoryIconQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type AutoCompleteKnowledgeBaseCategoryIconOption = ConfidentTake<
  AutocompleteSearchKnowledgeBaseCategoryIconQuery,
  'autocompleteSearchKnowledgeBaseCategoryIcon'
>[number]
