import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchIdoitUpObjectTypes.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchIdoitUpObjectTypesQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchIdoitUpObjectTypesQuery, Types.AutocompleteSearchIdoitUpObjectTypesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchIdoitUpObjectTypesDocument, defaults)
}

export function waitForAutocompleteSearchIdoitUpObjectTypesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchIdoitUpObjectTypesQuery>(Operations.AutocompleteSearchIdoitUpObjectTypesDocument)
}

export function mockAutocompleteSearchIdoitUpObjectTypesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchIdoitUpObjectTypesDocument, message, extensions);
}
