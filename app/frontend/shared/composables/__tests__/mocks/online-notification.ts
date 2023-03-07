// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { OnlineNotificationSeenDocument } from '@shared/entities/online-notification/graphql/mutations/seen.api'
import type { OnlineNotificationSeenPayload } from '@shared/graphql/types'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { nullableMock } from '@tests/support/utils'

export const mockOnlineNotificationSeenGql = () => {
  return mockGraphQLApi(OnlineNotificationSeenDocument).willResolve(
    nullableMock<OnlineNotificationSeenPayload>({
      success: true,
      errors: null,
    }),
  )
}
