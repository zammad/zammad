// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { SearchResult } from '#shared/graphql/types.ts'

import type { ResolversMeta } from '../builders/index.ts'
import type { DeepPartial } from '@apollo/client/utilities'

export default (
  _1: any,
  _2: any,
  meta: ResolversMeta,
): DeepPartial<SearchResult> => {
  return {
    // always generate types based on the query variable
    __typename: meta.variables.onlyIn as 'Ticket',
  }
}
