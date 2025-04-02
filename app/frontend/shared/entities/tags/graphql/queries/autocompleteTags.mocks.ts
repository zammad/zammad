import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteTags.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchTagQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchTagDocument, defaults)
}

export function waitForAutocompleteSearchTagQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchTagQuery>(Operations.AutocompleteSearchTagDocument)
}

export function mockAutocompleteSearchTagQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchTagDocument, message, extensions);
}
