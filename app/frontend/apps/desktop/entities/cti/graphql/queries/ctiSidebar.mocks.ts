import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ctiSidebar.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCtiSidebarQuery(defaults: Mocks.MockDefaultsValue<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CtiSidebarDocument, defaults)
}

export function waitForCtiSidebarQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CtiSidebarQuery>(Operations.CtiSidebarDocument)
}

export function mockCtiSidebarQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CtiSidebarDocument, message, extensions);
}
