import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIdoitUpObjectAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIdoitUpObjectAddMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIdoitUpObjectAddMutation, Types.TicketExternalReferencesIdoitUpObjectAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIdoitUpObjectAddDocument, defaults)
}

export function waitForTicketExternalReferencesIdoitUpObjectAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIdoitUpObjectAddMutation>(Operations.TicketExternalReferencesIdoitUpObjectAddDocument)
}

export function mockTicketExternalReferencesIdoitUpObjectAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIdoitUpObjectAddDocument, message, extensions);
}
