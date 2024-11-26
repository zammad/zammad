// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

// If a new array is returned and length differs, cache doesn't like it,
// and we need to tell apollo that it needs to just replace current state altogether
// this should be used only, if you are not using pagination.
export default function registerIncomingMerge(
  config: InMemoryCacheConfig,
  fieldName: string,
  referenceTypename: string,
): InMemoryCacheConfig {
  config.typePolicies ||= {}
  config.typePolicies.Query ||= {}
  config.typePolicies.Query.fields ||= {}
  config.typePolicies.Query.fields[fieldName] = {
    read(_, { args, toReference }) {
      if (!args) return undefined

      let { id } = args
      if (!('id' in args)) {
        id = args[fieldName][`${fieldName}Id`]
      }

      if (!id) return undefined

      return toReference({
        __typename: referenceTypename,
        id,
      })
    },
  }

  return config
}
