import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOverviewResetOrder.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentOverviewResetOrderMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOverviewResetOrderDocument, defaults)
}

export function waitForUserCurrentOverviewResetOrderMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOverviewResetOrderMutation>(Operations.UserCurrentOverviewResetOrderDocument)
}

export function mockUserCurrentOverviewResetOrderMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentOverviewResetOrderDocument, message, extensions);
}
