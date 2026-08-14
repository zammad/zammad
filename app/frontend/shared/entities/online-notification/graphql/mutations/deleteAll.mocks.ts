import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './deleteAll.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOnlineNotificationDeleteAllMutation(defaults: Mocks.MockDefaultsValue<Types.OnlineNotificationDeleteAllMutation, Types.OnlineNotificationDeleteAllMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.OnlineNotificationDeleteAllDocument, defaults)
}

export function waitForOnlineNotificationDeleteAllMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OnlineNotificationDeleteAllMutation>(Operations.OnlineNotificationDeleteAllDocument)
}

export function mockOnlineNotificationDeleteAllMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OnlineNotificationDeleteAllDocument, message, extensions);
}
