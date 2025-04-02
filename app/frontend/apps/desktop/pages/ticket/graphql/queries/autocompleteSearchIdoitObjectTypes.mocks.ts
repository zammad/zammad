import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchIdoitObjectTypes.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchIdoitObjectTypesQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchIdoitObjectTypesDocument, defaults)
}

export function waitForAutocompleteSearchIdoitObjectTypesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchIdoitObjectTypesQuery>(Operations.AutocompleteSearchIdoitObjectTypesDocument)
}

export function mockAutocompleteSearchIdoitObjectTypesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchIdoitObjectTypesDocument, message, extensions);
}
