import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './markAllAsSeen.api.ts'

export function mockOnlineNotificationMarkAllAsSeenMutation(defaults: Mocks.MockDefaultsValue<Types.OnlineNotificationMarkAllAsSeenMutation, Types.OnlineNotificationMarkAllAsSeenMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.OnlineNotificationMarkAllAsSeenDocument, defaults)
}

export function waitForOnlineNotificationMarkAllAsSeenMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OnlineNotificationMarkAllAsSeenMutation>(Operations.OnlineNotificationMarkAllAsSeenDocument)
}
