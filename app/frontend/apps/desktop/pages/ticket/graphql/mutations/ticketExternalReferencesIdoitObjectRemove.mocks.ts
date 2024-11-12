import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitObjectRemove.api.ts'

export function mockTicketExternalReferencesIdoitObjectRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitObjectRemoveDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitObjectRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitObjectRemoveMutation>(Operations.TicketExternalReferencesIdoitObjectRemoveDocument)
}
