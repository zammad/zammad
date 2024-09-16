import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './macrosUpdate.api.ts'

export function getMacrosUpdateSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.MacrosUpdateSubscription>(Operations.MacrosUpdateDocument)
}
