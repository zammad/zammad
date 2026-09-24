// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'

import { browserTabId } from '../utils/browserTabId.ts'
import { getSkipSubscriptions } from '../utils/getSkipSubscriptions.ts'

// Operations over the websocket pass the same information via the channel params instead.
const skipSubscriptionsLink = new ApolloLink((operation, forward) => {
  const skipSubscriptions = getSkipSubscriptions(operation)

  if (skipSubscriptions.length) {
    operation.setContext(({ headers }: { headers?: Record<string, string> }) => ({
      headers: {
        ...headers,
        'X-Zammad-Browser-Tab-Id': browserTabId,
        'X-Zammad-Skip-Subscriptions': skipSubscriptions.join(','),
      },
    }))
  }

  return forward(operation)
})

export default skipSubscriptionsLink
