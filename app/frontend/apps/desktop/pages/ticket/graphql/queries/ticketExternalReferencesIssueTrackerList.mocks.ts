import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIssueTrackerList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIssueTrackerItemListQuery(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIssueTrackerItemListDocument, defaults)
}

export function waitForTicketExternalReferencesIssueTrackerItemListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIssueTrackerItemListQuery>(Operations.TicketExternalReferencesIssueTrackerItemListDocument)
}

export function mockTicketExternalReferencesIssueTrackerItemListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIssueTrackerItemListDocument, message, extensions);
}
