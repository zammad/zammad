import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketOverviewsDocument = gql`
    query ticketOverviews($withTicketCount: Boolean!) {
  ticketOverviews {
    edges {
      node {
        ...overviewAttributes
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useTicketOverviewsQuery(variables: Types.TicketOverviewsQueryVariables | VueCompositionApi.Ref<Types.TicketOverviewsQueryVariables> | ReactiveFunction<Types.TicketOverviewsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>(TicketOverviewsDocument, variables, options);
}
export function useTicketOverviewsLazyQuery(variables?: Types.TicketOverviewsQueryVariables | VueCompositionApi.Ref<Types.TicketOverviewsQueryVariables> | ReactiveFunction<Types.TicketOverviewsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>(TicketOverviewsDocument, variables, options);
}
export type TicketOverviewsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>;