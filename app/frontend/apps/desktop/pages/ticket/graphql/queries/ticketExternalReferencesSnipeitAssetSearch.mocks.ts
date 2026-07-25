import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesSnipeitAssetSearch.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesSnipeitAssetSearchQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesSnipeitAssetSearchDocument, defaults)
}

export function waitForTicketExternalReferencesSnipeitAssetSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesSnipeitAssetSearchQuery>(Operations.TicketExternalReferencesSnipeitAssetSearchDocument)
}

export function mockTicketExternalReferencesSnipeitAssetSearchQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesSnipeitAssetSearchDocument, message, extensions);
}
