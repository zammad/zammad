import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './user.api.ts'

export function mockAutocompleteSearchUserQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchUserDocument, defaults)
}

export function waitForAutocompleteSearchUserQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchUserQuery>(Operations.AutocompleteSearchUserDocument)
}
