// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ClientSubscriptionContext } from '#shared/types/server/apollo/client.ts'

import type { Operation } from '@apollo/client/core'

export default function getSubscriptionContext(operation: Operation): ClientSubscriptionContext {
  const defaultSubscriptionContext: ClientSubscriptionContext = {
    keepAliveOnLogout: false,
  }
  const context = operation.getContext()
  const subscription: Partial<ClientSubscriptionContext> = context.subscription || {}

  return Object.assign(defaultSubscriptionContext, subscription)
}
