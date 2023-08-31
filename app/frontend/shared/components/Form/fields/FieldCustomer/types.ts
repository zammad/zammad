// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchUserQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type AutoCompleteCustomerOption = ConfidentTake<
  AutocompleteSearchUserQuery,
  'autocompleteSearchUser'
>[number]
