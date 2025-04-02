import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './links.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockPublicLinksQuery(defaults: Mocks.MockDefaultsValue<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.PublicLinksDocument, defaults)
}

export function waitForPublicLinksQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.PublicLinksQuery>(Operations.PublicLinksDocument)
}

export function mockPublicLinksQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.PublicLinksDocument, message, extensions);
}
