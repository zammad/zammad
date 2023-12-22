import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './onlineNotificationsCount.api.ts'

export function getOnlineNotificationsCountSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.OnlineNotificationsCountSubscription>(Operations.OnlineNotificationsCountDocument)
}
