// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { relayStylePagination } from '@apollo/client/utilities'

import type { FieldFunctionOptions, FieldPolicy } from '@apollo/client/cache/inmemory/policies'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import type { TRelayPageInfo } from '@apollo/client/utilities/policies/pagination'

interface Edge {
  node?: { __ref?: string } | null
  cursor?: string
}

interface Connection {
  edges: Edge[]
  pageInfo: TRelayPageInfo
}

type Merge = (
  existing: Connection | undefined,
  incoming: Connection,
  options: FieldFunctionOptions,
) => Connection

// The connection's cursors encode offsets. A call pushed to the top of the list shifts every
//   offset behind it by one, so the page fetched after the stored end cursor starts with the
//   row that is already loaded last; dropping the rows the list already holds keeps that from
//   duplicating it. Only for a page appended by cursor: a write without one replaces the list.
const withoutLoadedNodes = (existing: Connection | undefined, incoming: Connection): Connection => {
  if (!existing?.edges?.length || !incoming?.edges?.length) return incoming

  const loaded = new Set(existing.edges.map((edge) => edge.node?.__ref))

  return {
    ...incoming,
    edges: incoming.edges.filter((edge) => !loaded.has(edge.node?.__ref)),
  }
}

export default function register(config: InMemoryCacheConfig): InMemoryCacheConfig {
  const relay = relayStylePagination() as FieldPolicy<Connection>
  const relayMerge = relay.merge as Merge

  config.typePolicies ||= {}
  config.typePolicies.Query ||= {}
  config.typePolicies.Query.fields ||= {}
  config.typePolicies.Query.fields.ctiLogs = {
    ...relay,
    merge(existing, incoming, options) {
      const appended = options.args?.after ? withoutLoadedNodes(existing, incoming) : incoming

      return relayMerge(existing, appended, options)
    },
  }

  return config
}
