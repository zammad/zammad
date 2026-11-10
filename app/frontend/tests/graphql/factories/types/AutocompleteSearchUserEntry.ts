// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchUserEntry } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<AutocompleteSearchUserEntry> => ({
  __typename: 'AutocompleteSearchUserEntry',
  icon: null,
})
