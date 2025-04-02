import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchObjectAttributeExternalDataSource.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchObjectAttributeExternalDataSourceQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery, Types.AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchObjectAttributeExternalDataSourceDocument, defaults)
}

export function waitForAutocompleteSearchObjectAttributeExternalDataSourceQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery>(Operations.AutocompleteSearchObjectAttributeExternalDataSourceDocument)
}

export function mockAutocompleteSearchObjectAttributeExternalDataSourceQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchObjectAttributeExternalDataSourceDocument, message, extensions);
}
