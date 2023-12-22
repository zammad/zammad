import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './seen.api.ts'

export function mockOnlineNotificationSeenMutation(defaults: Mocks.MockDefaultsValue<Types.OnlineNotificationSeenMutation, Types.OnlineNotificationSeenMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.OnlineNotificationSeenDocument, defaults)
}

export function waitForOnlineNotificationSeenMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OnlineNotificationSeenMutation>(Operations.OnlineNotificationSeenDocument)
}
