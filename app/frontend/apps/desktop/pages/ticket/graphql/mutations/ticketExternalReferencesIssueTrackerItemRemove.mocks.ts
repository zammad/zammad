import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIssueTrackerItemRemove.api.ts'

export function mockTicketExternalReferencesIssueTrackerItemRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIssueTrackerItemRemoveMutation, Types.TicketExternalReferencesIssueTrackerItemRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIssueTrackerItemRemoveDocument, defaults)
}

export function waitForTicketExternalReferencesIssueTrackerItemRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIssueTrackerItemRemoveMutation>(Operations.TicketExternalReferencesIssueTrackerItemRemoveDocument)
}
