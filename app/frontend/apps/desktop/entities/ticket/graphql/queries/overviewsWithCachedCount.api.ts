import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useOverviewsWithCachedCountQuery(options: VueApolloComposable.useQuery.Options<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>) {
  return VueApolloComposable.useQuery<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>(OverviewsWithCachedCountDocument, options);
}
export function useOverviewsWithCachedCountLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>(OverviewsWithCachedCountDocument, options);
}
export type OverviewsWithCachedCountQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>;