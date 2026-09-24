// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ClientSkipSubscriptionsContext } from '#shared/types/server/apollo/client.ts'

import type { Operation } from '@apollo/client/core'

export const getSkipSubscriptions = (operation: Operation): ClientSkipSubscriptionsContext =>
  operation.getContext().skipSubscriptions || []
