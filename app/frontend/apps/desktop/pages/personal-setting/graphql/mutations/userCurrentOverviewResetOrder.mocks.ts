import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOverviewResetOrder.api.ts'

export function mockUserCurrentOverviewResetOrderMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOverviewResetOrderDocument, defaults)
}

export function waitForUserCurrentOverviewResetOrderMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOverviewResetOrderMutation>(Operations.UserCurrentOverviewResetOrderDocument)
}
