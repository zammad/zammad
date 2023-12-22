import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './organization.api.ts'

export function mockAutocompleteSearchOrganizationQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchOrganizationDocument, defaults)
}

export function waitForAutocompleteSearchOrganizationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchOrganizationQuery>(Operations.AutocompleteSearchOrganizationDocument)
}
