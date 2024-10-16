import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchTicket.api.ts'

export function mockAutocompleteSearchTicketQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchTicketDocument, defaults)
}

export function waitForAutocompleteSearchTicketQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchTicketQuery>(Operations.AutocompleteSearchTicketDocument)
}
