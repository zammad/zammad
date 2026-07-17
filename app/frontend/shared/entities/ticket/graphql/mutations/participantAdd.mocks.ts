import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './participantAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketParticipantAddMutation(defaults: Mocks.MockDefaultsValue<Types.TicketParticipantAddMutation, Types.TicketParticipantAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketParticipantAddDocument, defaults)
}

export function waitForTicketParticipantAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketParticipantAddMutation>(Operations.TicketParticipantAddDocument)
}

export function mockTicketParticipantAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketParticipantAddDocument, message, extensions);
}
