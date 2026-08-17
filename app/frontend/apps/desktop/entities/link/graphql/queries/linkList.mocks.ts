import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './linkList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockLinkListQuery(defaults: Mocks.MockDefaultsValue<Types.LinkListQuery, Types.LinkListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.LinkListDocument, defaults)
}

export function waitForLinkListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.LinkListQuery>(Operations.LinkListDocument)
}

export function mockLinkListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.LinkListDocument, message, extensions);
}
