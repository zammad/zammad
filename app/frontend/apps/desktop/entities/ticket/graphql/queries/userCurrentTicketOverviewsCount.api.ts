import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTicketOverviewsCountDocument = gql`
    query userCurrentTicketOverviewsCount($ignoreUserConditions: Boolean!, $cacheTtl: Int!) {
  userCurrentTicketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    id
    cachedTicketCount(cacheTtl: $cacheTtl)
  }
}
    `;
export function useUserCurrentTicketOverviewsCountQuery(variables: Types.UserCurrentTicketOverviewsCountQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTicketOverviewsCountQueryVariables> | ReactiveFunction<Types.UserCurrentTicketOverviewsCountQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>(UserCurrentTicketOverviewsCountDocument, variables, options);
}
export function useUserCurrentTicketOverviewsCountLazyQuery(variables?: Types.UserCurrentTicketOverviewsCountQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTicketOverviewsCountQueryVariables> | ReactiveFunction<Types.UserCurrentTicketOverviewsCountQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>(UserCurrentTicketOverviewsCountDocument, variables, options);
}
export type UserCurrentTicketOverviewsCountQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>;