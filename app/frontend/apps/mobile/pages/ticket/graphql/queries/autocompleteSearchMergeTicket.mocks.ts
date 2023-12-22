import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchMergeTicket.api.ts'

export function mockAutocompleteSearchMergeTicketQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchMergeTicketDocument, defaults)
}

export function waitForAutocompleteSearchMergeTicketQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchMergeTicketQuery>(Operations.AutocompleteSearchMergeTicketDocument)
}
