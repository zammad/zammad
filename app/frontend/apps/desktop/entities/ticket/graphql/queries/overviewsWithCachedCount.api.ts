import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OverviewsWithCachedCountDocument = gql`
    query overviewsWithCachedCount($ignoreUserConditions: Boolean!, $filterOverviewIds: [ID!], $cacheTtl: Int!) {
  ticketOverviews(
    filterOverviewIds: $filterOverviewIds
    ignoreUserConditions: $ignoreUserConditions
  ) {
    id
    cachedTicketCount(cacheTtl: $cacheTtl)
  }
}
    `;
export function useOverviewsWithCachedCountQuery(variables: Types.OverviewsWithCachedCountQueryVariables | VueCompositionApi.Ref<Types.OverviewsWithCachedCountQueryVariables> | ReactiveFunction<Types.OverviewsWithCachedCountQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>(OverviewsWithCachedCountDocument, variables, options);
}
export function useOverviewsWithCachedCountLazyQuery(variables?: Types.OverviewsWithCachedCountQueryVariables | VueCompositionApi.Ref<Types.OverviewsWithCachedCountQueryVariables> | ReactiveFunction<Types.OverviewsWithCachedCountQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>(OverviewsWithCachedCountDocument, variables, options);
}
export type OverviewsWithCachedCountQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>;