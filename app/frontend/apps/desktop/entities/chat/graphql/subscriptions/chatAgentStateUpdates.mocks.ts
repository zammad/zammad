import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatAgentStateUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getChatAgentStateUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.ChatAgentStateUpdatesSubscription>(Operations.ChatAgentStateUpdatesDocument)
}
