import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './delete.api.ts'

export function mockOnlineNotificationDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.OnlineNotificationDeleteDocument, defaults)
}

export function waitForOnlineNotificationDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OnlineNotificationDeleteMutation>(Operations.OnlineNotificationDeleteDocument)
}
