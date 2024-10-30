import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketExternalReferencesIssueTrackerItemAddMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables>(TicketExternalReferencesIssueTrackerItemAddDocument, options);
}
export type TicketExternalReferencesIssueTrackerItemAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketExternalReferencesIssueTrackerItemAddMutation, Types.TicketExternalReferencesIssueTrackerItemAddMutationVariables>;