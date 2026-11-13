import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIssueTrackerItemAddDocument = gql`
    mutation ticketExternalReferencesIssueTrackerItemAdd($issueTrackerLink: UriHttpString!, $issueTrackerType: EnumTicketExternalReferencesIssueTrackerType!, $ticketId: ID) {
  ticketExternalReferencesIssueTrackerItemAdd(
    issueTrackerLink: $issueTrackerLink
    issueTrackerType: $issueTrackerType
    ticketId: $ticketId
  ) {
    issueTrackerItem {
      assignees
      issueId
      issueType {
        color
        name
      }
      labels {
        color
        textColor
        title
      }
      milestone
      state
      title
      url
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesIssueTrackerItemAddMutation(options: VueApolloComposable.useMutation.Options<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables>(TicketExternalReferencesIssueTrackerItemAddDocument, options);
}
export type TicketExternalReferencesIssueTrackerItemAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables>;