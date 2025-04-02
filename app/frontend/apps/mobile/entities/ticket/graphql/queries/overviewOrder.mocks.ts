import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './overviewOrder.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketOverviewOrderQuery(defaults: Mocks.MockDefaultsValue<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketOverviewOrderDocument, defaults)
}

export function waitForTicketOverviewOrderQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketOverviewOrderQuery>(Operations.TicketOverviewOrderDocument)
}

export function mockTicketOverviewOrderQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketOverviewOrderDocument, message, extensions);
}
