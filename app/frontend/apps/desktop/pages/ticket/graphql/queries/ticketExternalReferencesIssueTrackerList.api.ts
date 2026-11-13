import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIssueTrackerItemListDocument = gql`
    query ticketExternalReferencesIssueTrackerItemList($issueTrackerType: EnumTicketExternalReferencesIssueTrackerType!, $ticketId: ID, $issueTrackerLinks: [UriHttpString!]) {
  ticketExternalReferencesIssueTrackerItemList(
    issueTrackerType: $issueTrackerType
    input: { issueTrackerLinks: $issueTrackerLinks, ticketId: $ticketId }
  ) {
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
}
    `;
export function useTicketExternalReferencesIssueTrackerItemListQuery(options: VueApolloComposable.useQuery.Options<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>(TicketExternalReferencesIssueTrackerItemListDocument, options);
}
export function useTicketExternalReferencesIssueTrackerItemListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>(TicketExternalReferencesIssueTrackerItemListDocument, options);
}
export type TicketExternalReferencesIssueTrackerItemListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>;