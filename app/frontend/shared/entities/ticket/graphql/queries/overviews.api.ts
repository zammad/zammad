import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OverviewsDocument = gql`
    query overviews($withTicketCount: Boolean!) {
  overviews {
    edges {
      node {
        id
        name
        link
        prio
        order
        view
        active
        ticketCount @include(if: $withTicketCount)
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
export function useOverviewsQuery(variables: Types.OverviewsQueryVariables | VueCompositionApi.Ref<Types.OverviewsQueryVariables> | ReactiveFunction<Types.OverviewsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OverviewsQuery, Types.OverviewsQueryVariables>(OverviewsDocument, variables, options);
}
export function useOverviewsLazyQuery(variables: Types.OverviewsQueryVariables | VueCompositionApi.Ref<Types.OverviewsQueryVariables> | ReactiveFunction<Types.OverviewsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.OverviewsQuery, Types.OverviewsQueryVariables>(OverviewsDocument, variables, options);
}
export type OverviewsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OverviewsQuery, Types.OverviewsQueryVariables>;