import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTicketOverviewsCountDocument = gql`
    query userCurrentTicketOverviewsCount($ignoreUserConditions: Boolean!, $cacheTtl: Int!) {
  userCurrentTicketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    id
    cachedTicketCount(cacheTtl: $cacheTtl)
  }
}
    `;
export function useUserCurrentTicketOverviewsCountQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>(UserCurrentTicketOverviewsCountDocument, options);
}
export function useUserCurrentTicketOverviewsCountLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>(UserCurrentTicketOverviewsCountDocument, options);
}
export type UserCurrentTicketOverviewsCountQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>;