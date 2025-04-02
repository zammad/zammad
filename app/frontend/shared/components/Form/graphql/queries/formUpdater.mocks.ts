import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './formUpdater.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockFormUpdaterQuery(defaults: Mocks.MockDefaultsValue<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.FormUpdaterDocument, defaults)
}

export function waitForFormUpdaterQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.FormUpdaterQuery>(Operations.FormUpdaterDocument)
}

export function mockFormUpdaterQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.FormUpdaterDocument, message, extensions);
}
