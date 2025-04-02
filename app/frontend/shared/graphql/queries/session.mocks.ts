import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './session.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSessionQuery(defaults: Mocks.MockDefaultsValue<Types.SessionQuery, Types.SessionQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.SessionDocument, defaults)
}

export function waitForSessionQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SessionQuery>(Operations.SessionDocument)
}

export function mockSessionQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SessionDocument, message, extensions);
}
