import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './overviewTicketCount.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketOverviewTicketCountQuery(defaults: Mocks.MockDefaultsValue<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketOverviewTicketCountDocument, defaults)
}

export function waitForTicketOverviewTicketCountQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketOverviewTicketCountQuery>(Operations.TicketOverviewTicketCountDocument)
}

export function mockTicketOverviewTicketCountQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketOverviewTicketCountDocument, message, extensions);
}
