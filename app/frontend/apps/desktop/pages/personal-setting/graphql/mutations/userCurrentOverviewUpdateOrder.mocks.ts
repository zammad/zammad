import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOverviewUpdateOrder.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentOverviewUpdateOrderMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOverviewUpdateOrderMutation, Types.UserCurrentOverviewUpdateOrderMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOverviewUpdateOrderDocument, defaults)
}

export function waitForUserCurrentOverviewUpdateOrderMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOverviewUpdateOrderMutation>(Operations.UserCurrentOverviewUpdateOrderDocument)
}

export function mockUserCurrentOverviewUpdateOrderMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentOverviewUpdateOrderDocument, message, extensions);
}
