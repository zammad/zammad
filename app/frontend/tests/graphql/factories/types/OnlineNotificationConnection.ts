// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { type OnlineNotificationConnection } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<OnlineNotificationConnection> => ({
  __typename: 'OnlineNotificationConnection',
  edges: [],
  pageInfo: {
    __typename: 'PageInfo',
    endCursor: null,
    hasNextPage: false,
  },
})
