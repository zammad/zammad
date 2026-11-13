import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIssueTrackerItemRemoveDocument = gql`
    mutation ticketExternalReferencesIssueTrackerItemRemove($issueTrackerLink: UriHttpString!, $issueTrackerType: EnumTicketExternalReferencesIssueTrackerType!, $ticketId: ID!) {
  ticketExternalReferencesIssueTrackerItemRemove(
    issueTrackerLink: $issueTrackerLink
    issueTrackerType: $issueTrackerType
    ticketId: $ticketId
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesIssueTrackerItemRemoveMutation(options: VueApolloComposable.useMutation.Options<Types.TicketExternalReferencesIssueTrackerItemRemoveMutation, Types.TicketExternalReferencesIssueTrackerItemRemoveMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIssueTrackerItemRemoveMutation, Types.TicketExternalReferencesIssueTrackerItemRemoveMutationVariables>(TicketExternalReferencesIssueTrackerItemRemoveDocument, options);
}
export type TicketExternalReferencesIssueTrackerItemRemoveMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketExternalReferencesIssueTrackerItemRemoveMutation, Types.TicketExternalReferencesIssueTrackerItemRemoveMutationVariables>;