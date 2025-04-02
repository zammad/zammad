import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIssueTrackerItemRemove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIssueTrackerItemRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIssueTrackerItemRemoveMutation, Types.TicketExternalReferencesIssueTrackerItemRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIssueTrackerItemRemoveDocument, defaults)
}

export function waitForTicketExternalReferencesIssueTrackerItemRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIssueTrackerItemRemoveMutation>(Operations.TicketExternalReferencesIssueTrackerItemRemoveDocument)
}

export function mockTicketExternalReferencesIssueTrackerItemRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIssueTrackerItemRemoveDocument, message, extensions);
}
