import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitUpObjectList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitUpObjectListQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitUpObjectListQuery, Types.TicketExternalReferencesIdoitUpObjectListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitUpObjectListDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitUpObjectListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitUpObjectListQuery>(Operations.TicketExternalReferencesIdoitUpObjectListDocument)
}

export function mockTicketExternalReferencesIdoitUpObjectListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitUpObjectListDocument, message, extensions);
}
