import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitObjectRemove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitObjectRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitObjectRemoveDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitObjectRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitObjectRemoveMutation>(Operations.TicketExternalReferencesIdoitObjectRemoveDocument)
}

export function mockTicketExternalReferencesIdoitObjectRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitObjectRemoveDocument, message, extensions);
}
