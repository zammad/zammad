import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './searchTaskbarItemStateUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getSearchTaskbarItemStateUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.SearchTaskbarItemStateUpdatesSubscription>(Operations.SearchTaskbarItemStateUpdatesDocument)
}
