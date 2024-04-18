import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountAvatarUpdates.api.ts'

export function getAccountAvatarUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.AccountAvatarUpdatesSubscription>(Operations.AccountAvatarUpdatesDocument)
}
