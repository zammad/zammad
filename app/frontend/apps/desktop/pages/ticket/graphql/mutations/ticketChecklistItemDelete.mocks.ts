import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklistItemDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketChecklistItemDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketChecklistItemDeleteDocument, defaults)
}

export function waitForTicketChecklistItemDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketChecklistItemDeleteMutation>(Operations.TicketChecklistItemDeleteDocument)
}

export function mockTicketChecklistItemDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketChecklistItemDeleteDocument, message, extensions);
}
