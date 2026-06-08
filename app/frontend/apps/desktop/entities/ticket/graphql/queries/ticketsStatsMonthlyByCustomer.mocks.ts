import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsStatsMonthlyByCustomer.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsStatsMonthlyByCustomerQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsStatsMonthlyByCustomerDocument, defaults)
}

export function waitForTicketsStatsMonthlyByCustomerQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsStatsMonthlyByCustomerQuery>(Operations.TicketsStatsMonthlyByCustomerDocument)
}

export function mockTicketsStatsMonthlyByCustomerQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsStatsMonthlyByCustomerDocument, message, extensions);
}
