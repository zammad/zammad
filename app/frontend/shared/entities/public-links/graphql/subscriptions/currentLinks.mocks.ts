import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './currentLinks.api.ts'

export function getPublicLinkUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.PublicLinkUpdatesSubscription>(Operations.PublicLinkUpdatesDocument)
}
