import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './aiTextToolUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getAiTextToolUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.AiTextToolUpdatesSubscription>(Operations.AiTextToolUpdatesDocument)
}
