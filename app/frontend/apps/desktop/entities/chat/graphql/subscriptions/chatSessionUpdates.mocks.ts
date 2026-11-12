import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSessionUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getChatSessionUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.ChatSessionUpdatesSubscription>(Operations.ChatSessionUpdatesDocument)
}
