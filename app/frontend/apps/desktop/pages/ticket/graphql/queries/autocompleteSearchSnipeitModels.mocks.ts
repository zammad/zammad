import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchSnipeitModels.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchSnipeitModelsQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchSnipeitModelsDocument, defaults)
}

export function waitForAutocompleteSearchSnipeitModelsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchSnipeitModelsQuery>(Operations.AutocompleteSearchSnipeitModelsDocument)
}

export function mockAutocompleteSearchSnipeitModelsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchSnipeitModelsDocument, message, extensions);
}
