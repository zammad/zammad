import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTaskbarItemDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemDeleteMutation, Types.UserCurrentTaskbarItemDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemDeleteDocument, defaults)
}

export function waitForUserCurrentTaskbarItemDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemDeleteMutation>(Operations.UserCurrentTaskbarItemDeleteDocument)
}

export function mockUserCurrentTaskbarItemDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTaskbarItemDeleteDocument, message, extensions);
}
