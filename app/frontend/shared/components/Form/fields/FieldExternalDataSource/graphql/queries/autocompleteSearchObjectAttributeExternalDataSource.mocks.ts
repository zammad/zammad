import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchObjectAttributeExternalDataSource.api.ts'

export function mockAutocompleteSearchObjectAttributeExternalDataSourceQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery, Types.AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchObjectAttributeExternalDataSourceDocument, defaults)
}

export function waitForAutocompleteSearchObjectAttributeExternalDataSourceQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery>(Operations.AutocompleteSearchObjectAttributeExternalDataSourceDocument)
}
