import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './recipient.api.ts'

export function mockAutocompleteSearchRecipientQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchRecipientDocument, defaults)
}

export function waitForAutocompleteSearchRecipientQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchRecipientQuery>(Operations.AutocompleteSearchRecipientDocument)
}
