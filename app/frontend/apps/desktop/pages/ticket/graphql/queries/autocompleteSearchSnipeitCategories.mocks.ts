import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchSnipeitCategories.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchSnipeitCategoriesQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchSnipeitCategoriesDocument, defaults)
}

export function waitForAutocompleteSearchSnipeitCategoriesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchSnipeitCategoriesQuery>(Operations.AutocompleteSearchSnipeitCategoriesDocument)
}

export function mockAutocompleteSearchSnipeitCategoriesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchSnipeitCategoriesDocument, message, extensions);
}
