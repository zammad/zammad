import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesSnipeitAssetList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesSnipeitAssetListQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesSnipeitAssetListDocument, defaults)
}

export function waitForTicketExternalReferencesSnipeitAssetListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesSnipeitAssetListQuery>(Operations.TicketExternalReferencesSnipeitAssetListDocument)
}

export function mockTicketExternalReferencesSnipeitAssetListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesSnipeitAssetListDocument, message, extensions);
}
