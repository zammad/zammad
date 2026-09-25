import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ctiLogUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getCtiLogUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.CtiLogUpdatesSubscription>(Operations.CtiLogUpdatesDocument)
}
