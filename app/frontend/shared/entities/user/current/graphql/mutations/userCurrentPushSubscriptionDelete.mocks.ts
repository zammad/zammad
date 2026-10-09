import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentPushSubscriptionDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentPushSubscriptionDelete(defaults: Mocks.MockDefaultsValue<Types.UserCurrentPushSubscriptionDeleteMutation, Types.UserCurrentPushSubscriptionDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentPushSubscriptionDeleteDocument, defaults)
}

export function waitForUserCurrentPushSubscriptionDeleteCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentPushSubscriptionDeleteMutation>(Operations.UserCurrentPushSubscriptionDeleteDocument)
}

export function mockUserCurrentPushSubscriptionDeleteError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentPushSubscriptionDeleteDocument, message, extensions);
}
