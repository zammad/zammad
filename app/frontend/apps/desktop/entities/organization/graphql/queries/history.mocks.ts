import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './history.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOrganizationHistoryQuery(defaults: Mocks.MockDefaultsValue<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.OrganizationHistoryDocument, defaults)
}

export function waitForOrganizationHistoryQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OrganizationHistoryQuery>(Operations.OrganizationHistoryDocument)
}

export function mockOrganizationHistoryQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OrganizationHistoryDocument, message, extensions);
}
