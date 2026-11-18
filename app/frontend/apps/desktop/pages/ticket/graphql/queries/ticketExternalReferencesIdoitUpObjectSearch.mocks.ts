import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitUpObjectSearch.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitUpObjectSearchQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitUpObjectSearchQuery, Types.TicketExternalReferencesIdoitUpObjectSearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitUpObjectSearchDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitUpObjectSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitUpObjectSearchQuery>(Operations.TicketExternalReferencesIdoitUpObjectSearchDocument)
}

export function mockTicketExternalReferencesIdoitUpObjectSearchQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitUpObjectSearchDocument, message, extensions);
}
