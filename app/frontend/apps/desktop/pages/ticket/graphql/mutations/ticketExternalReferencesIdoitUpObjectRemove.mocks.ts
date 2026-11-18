import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitUpObjectRemove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitUpObjectRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitUpObjectRemoveMutation, Types.TicketExternalReferencesIdoitUpObjectRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitUpObjectRemoveDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitUpObjectRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitUpObjectRemoveMutation>(Operations.TicketExternalReferencesIdoitUpObjectRemoveDocument)
}

export function mockTicketExternalReferencesIdoitUpObjectRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitUpObjectRemoveDocument, message, extensions);
}
