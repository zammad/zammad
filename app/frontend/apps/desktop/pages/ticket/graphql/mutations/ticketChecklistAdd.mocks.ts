import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklistAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketChecklistAddMutation(defaults: Mocks.MockDefaultsValue<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketChecklistAddDocument, defaults)
}

export function waitForTicketChecklistAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketChecklistAddMutation>(Operations.TicketChecklistAddDocument)
}

export function mockTicketChecklistAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketChecklistAddDocument, message, extensions);
}
