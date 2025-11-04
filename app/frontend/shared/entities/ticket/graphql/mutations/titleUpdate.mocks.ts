import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './titleUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketTitleUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketTitleUpdateDocument, defaults)
}

export function waitForTicketTitleUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketTitleUpdateMutation>(Operations.TicketTitleUpdateDocument)
}

export function mockTicketTitleUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketTitleUpdateDocument, message, extensions);
}
