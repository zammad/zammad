import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './participantRemove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketParticipantRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TicketParticipantRemoveMutation, Types.TicketParticipantRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketParticipantRemoveDocument, defaults)
}

export function waitForTicketParticipantRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketParticipantRemoveMutation>(Operations.TicketParticipantRemoveDocument)
}

export function mockTicketParticipantRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketParticipantRemoveDocument, message, extensions);
}
