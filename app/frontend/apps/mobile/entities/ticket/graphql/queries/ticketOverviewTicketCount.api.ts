import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketOverviewTicketCountDocument = gql`
    query ticketOverviewTicketCount {
  ticketOverviews {
    edges {
      node {
        id
        ticketCount
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    `;
export function useTicketOverviewTicketCountQuery(options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>(TicketOverviewTicketCountDocument, {}, options);
}
export function useTicketOverviewTicketCountLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>(TicketOverviewTicketCountDocument, {}, options);
}
export type TicketOverviewTicketCountQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>;