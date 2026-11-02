// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache'

// If a new array is returned and length differs, cache doesn't like it,
// and we need to tell apollo that it needs to just replace current state altogether
// this should be used only, if you are not using pagination.
export default function registerIncomingQueryMerge(
  config: InMemoryCacheConfig,
  fieldName: string,
  referenceTypename: string,
): InMemoryCacheConfig {
  config.typePolicies ||= {}
  config.typePolicies.Query ||= {}
  config.typePolicies.Query.fields ||= {}
  config.typePolicies.Query.fields[fieldName] = {
    read(existing, { args, toReference }) {
      // A result stored under this exact field key - including a `null` for a
      //  missing entity - wins over the redirect, otherwise the field reads as
      //  missing and Apollo reports a partial cache result.
      if (existing !== undefined) return existing

      if (!args) return undefined

      const id = args.id ?? args[`${fieldName}Id`]

      if (!id) return undefined

      return toReference({
        __typename: referenceTypename,
        id,
      })
    },
  }

  return config
}
