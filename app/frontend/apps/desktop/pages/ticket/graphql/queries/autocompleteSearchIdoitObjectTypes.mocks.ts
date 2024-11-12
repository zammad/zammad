import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchIdoitObjectTypes.api.ts'

export function mockAutocompleteSearchIdoitObjectTypesQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchIdoitObjectTypesDocument, defaults)
}

export function waitForAutocompleteSearchIdoitObjectTypesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchIdoitObjectTypesQuery>(Operations.AutocompleteSearchIdoitObjectTypesDocument)
}
