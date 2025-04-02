import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './user.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserQuery(defaults: Mocks.MockDefaultsValue<Types.UserQuery, Types.UserQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserDocument, defaults)
}

export function waitForUserQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserQuery>(Operations.UserDocument)
}

export function mockUserQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserDocument, message, extensions);
}
