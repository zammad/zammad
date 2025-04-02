import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklistDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketChecklistDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketChecklistDeleteDocument, defaults)
}

export function waitForTicketChecklistDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketChecklistDeleteMutation>(Operations.TicketChecklistDeleteDocument)
}

export function mockTicketChecklistDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketChecklistDeleteDocument, message, extensions);
}
