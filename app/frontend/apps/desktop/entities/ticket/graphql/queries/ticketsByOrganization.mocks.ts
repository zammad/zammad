import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsByOrganization.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsByOrganizationQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsByOrganizationDocument, defaults)
}

export function waitForTicketsByOrganizationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsByOrganizationQuery>(Operations.TicketsByOrganizationDocument)
}

export function mockTicketsByOrganizationQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsByOrganizationDocument, message, extensions);
}
