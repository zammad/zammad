import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentRecentViewReset.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentRecentViewResetMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentRecentViewResetMutation, Types.UserCurrentRecentViewResetMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentRecentViewResetDocument, defaults)
}

export function waitForUserCurrentRecentViewResetMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentRecentViewResetMutation>(Operations.UserCurrentRecentViewResetDocument)
}

export function mockUserCurrentRecentViewResetMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentRecentViewResetDocument, message, extensions);
}
