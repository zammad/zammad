import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './checklistTemplateUpdates.api.ts'

export function getChecklistTemplateUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.ChecklistTemplateUpdatesSubscription>(Operations.ChecklistTemplateUpdatesDocument)
}
