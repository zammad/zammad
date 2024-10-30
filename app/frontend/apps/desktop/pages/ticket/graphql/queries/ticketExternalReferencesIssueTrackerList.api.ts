import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesIssueTrackerItemListDocument = gql`
    query ticketExternalReferencesIssueTrackerItemList($issueTrackerType: EnumTicketExternalReferencesIssueTrackerType!, $ticketId: ID, $issueTrackerLinks: [UriHttpString!]) {
  ticketExternalReferencesIssueTrackerItemList(
    issueTrackerType: $issueTrackerType
    input: {issueTrackerLinks: $issueTrackerLinks, ticketId: $ticketId}
  ) {
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
}
    `;
export function useTicketExternalReferencesIssueTrackerItemListQuery(variables: Types.TicketExternalReferencesIssueTrackerItemListQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesIssueTrackerItemListQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>(TicketExternalReferencesIssueTrackerItemListDocument, variables, options);
}
export function useTicketExternalReferencesIssueTrackerItemListLazyQuery(variables?: Types.TicketExternalReferencesIssueTrackerItemListQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesIssueTrackerItemListQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>(TicketExternalReferencesIssueTrackerItemListDocument, variables, options);
}
export type TicketExternalReferencesIssueTrackerItemListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketExternalReferencesIssueTrackerItemListQuery, Types.TicketExternalReferencesIssueTrackerItemListQueryVariables>;