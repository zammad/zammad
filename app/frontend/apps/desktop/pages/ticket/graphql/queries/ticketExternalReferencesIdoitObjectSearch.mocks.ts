import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitObjectSearch.api.ts'

export function mockTicketExternalReferencesIdoitObjectSearchQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitObjectSearchDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitObjectSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitObjectSearchQuery>(Operations.TicketExternalReferencesIdoitObjectSearchDocument)
}
