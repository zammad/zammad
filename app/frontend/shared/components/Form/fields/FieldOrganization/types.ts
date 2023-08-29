// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchOrganizationQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type AutoCompleteOrganizationOption = ConfidentTake<
  AutocompleteSearchOrganizationQuery,
  'autocompleteSearchOrganization'
>[number]
