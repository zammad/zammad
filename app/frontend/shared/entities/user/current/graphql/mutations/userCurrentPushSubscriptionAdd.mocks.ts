import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentPushSubscriptionAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentPushSubscriptionAdd(defaults: Mocks.MockDefaultsValue<Types.UserCurrentPushSubscriptionAddMutation, Types.UserCurrentPushSubscriptionAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentPushSubscriptionAddDocument, defaults)
}

export function waitForUserCurrentPushSubscriptionAddCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentPushSubscriptionAddMutation>(Operations.UserCurrentPushSubscriptionAddDocument)
}

export function mockUserCurrentPushSubscriptionAddError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentPushSubscriptionAddDocument, message, extensions);
}
