import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitObjectAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitObjectAddMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitObjectAddMutation, Types.TicketExternalReferencesIdoitObjectAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitObjectAddDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitObjectAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitObjectAddMutation>(Operations.TicketExternalReferencesIdoitObjectAddDocument)
}

export function mockTicketExternalReferencesIdoitObjectAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitObjectAddDocument, message, extensions);
}
