import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsByOverviewSlim.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsByOverviewSlimQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsByOverviewSlimDocument, defaults)
}

export function waitForTicketsByOverviewSlimQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsByOverviewSlimQuery>(Operations.TicketsByOverviewSlimDocument)
}

export function mockTicketsByOverviewSlimQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsByOverviewSlimDocument, message, extensions);
}
