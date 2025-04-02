import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './generic.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchGenericQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchGenericDocument, defaults)
}

export function waitForAutocompleteSearchGenericQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchGenericQuery>(Operations.AutocompleteSearchGenericDocument)
}

export function mockAutocompleteSearchGenericQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchGenericDocument, message, extensions);
}
