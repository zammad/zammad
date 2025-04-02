import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './delete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOnlineNotificationDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.OnlineNotificationDeleteDocument, defaults)
}

export function waitForOnlineNotificationDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OnlineNotificationDeleteMutation>(Operations.OnlineNotificationDeleteDocument)
}

export function mockOnlineNotificationDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OnlineNotificationDeleteDocument, message, extensions);
}
