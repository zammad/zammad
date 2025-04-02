import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesIssueTrackerItemAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesIssueTrackerItemAddMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesIssueTrackerItemAddDocument, defaults)
}

export function waitForTicketExternalReferencesIssueTrackerItemAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesIssueTrackerItemAddMutation>(Operations.TicketExternalReferencesIssueTrackerItemAddDocument)
}

export function mockTicketExternalReferencesIssueTrackerItemAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesIssueTrackerItemAddDocument, message, extensions);
}
