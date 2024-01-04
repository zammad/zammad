// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchObjectAttributeExternalDataSourceQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type AutoCompleteExternalDataSourceOption = ConfidentTake<
  AutocompleteSearchObjectAttributeExternalDataSourceQuery,
  'autocompleteSearchObjectAttributeExternalDataSource'
>[number]
