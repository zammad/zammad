// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { CtiLog } from '#shared/graphql/types.ts'

import type { RouteLocationNamedRaw } from 'vue-router'

// Without a tab id the create route opens a fresh tab, so a form the agent left
//   unsaved in another create tab is not touched. The form updater seeds the
//   customer field from the query.
export const customerTicketCreateRoute = (customer: {
  internalId: number
}): RouteLocationNamedRaw => ({
  name: 'TicketCreate',
  query: { customer_id: customer.internalId },
})

// A detected customer goes by id, otherwise the number stands in for the customer.
export const callerTicketCreateRoute = (
  log: Pick<CtiLog, 'from' | 'fromPretty'>,
  customer?: Maybe<{ internalId: number }>,
): RouteLocationNamedRaw =>
  customer
    ? customerTicketCreateRoute(customer)
    : { name: 'TicketCreate', query: { customer_phone: log.fromPretty || log.from } }
