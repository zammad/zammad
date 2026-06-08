import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsStatsMonthlyByOrganization.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsStatsMonthlyByOrganizationQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsStatsMonthlyByOrganizationDocument, defaults)
}

export function waitForTicketsStatsMonthlyByOrganizationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsStatsMonthlyByOrganizationQuery>(Operations.TicketsStatsMonthlyByOrganizationDocument)
}

export function mockTicketsStatsMonthlyByOrganizationQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsStatsMonthlyByOrganizationDocument, message, extensions);
}
