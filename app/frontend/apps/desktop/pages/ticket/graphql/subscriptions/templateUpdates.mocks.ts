import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './templateUpdates.api.ts'

export function getTemplateUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TemplateUpdatesSubscription>(Operations.TemplateUpdatesDocument)
}
