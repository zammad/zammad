import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './currentUser.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCurrentUserQuery(defaults: Mocks.MockDefaultsValue<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CurrentUserDocument, defaults)
}

export function waitForCurrentUserQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CurrentUserQuery>(Operations.CurrentUserDocument)
}

export function mockCurrentUserQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CurrentUserDocument, message, extensions);
}
