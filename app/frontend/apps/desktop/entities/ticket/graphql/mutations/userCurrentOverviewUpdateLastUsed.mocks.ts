import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOverviewUpdateLastUsed.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentOverviewUpdateLastUsedMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOverviewUpdateLastUsedDocument, defaults)
}

export function waitForUserCurrentOverviewUpdateLastUsedMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOverviewUpdateLastUsedMutation>(Operations.UserCurrentOverviewUpdateLastUsedDocument)
}

export function mockUserCurrentOverviewUpdateLastUsedMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentOverviewUpdateLastUsedDocument, message, extensions);
}
