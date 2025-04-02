import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitObjectList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitObjectListQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitObjectListDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitObjectListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitObjectListQuery>(Operations.TicketExternalReferencesIdoitObjectListDocument)
}

export function mockTicketExternalReferencesIdoitObjectListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitObjectListDocument, message, extensions);
}
