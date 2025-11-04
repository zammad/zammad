import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketInfoForPopover.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketInfoForPopoverQuery(defaults: Mocks.MockDefaultsValue<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketInfoForPopoverDocument, defaults)
}

export function waitForTicketInfoForPopoverQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketInfoForPopoverQuery>(Operations.TicketInfoForPopoverDocument)
}

export function mockTicketInfoForPopoverQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketInfoForPopoverDocument, message, extensions);
}
