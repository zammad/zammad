import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitObjectSearch.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitObjectSearchQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitObjectSearchDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitObjectSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitObjectSearchQuery>(Operations.TicketExternalReferencesIdoitObjectSearchDocument)
}

export function mockTicketExternalReferencesIdoitObjectSearchQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitObjectSearchDocument, message, extensions);
}
