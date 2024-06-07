import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './generic.api.ts'

export function mockAutocompleteSearchGenericQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchGenericDocument, defaults)
}

export function waitForAutocompleteSearchGenericQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchGenericQuery>(Operations.AutocompleteSearchGenericDocument)
}
