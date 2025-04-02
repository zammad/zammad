import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentOverviewListDocument = gql`
    query userCurrentOverviewList($ignoreUserConditions: Boolean!) {
  userCurrentTicketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    id
    name
    organizationShared
    outOfOffice
  }
}
    `;
export function useUserCurrentOverviewListQuery(variables: Types.UserCurrentOverviewListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentOverviewListQueryVariables> | ReactiveFunction<Types.UserCurrentOverviewListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>(UserCurrentOverviewListDocument, variables, options);
}
export function useUserCurrentOverviewListLazyQuery(variables?: Types.UserCurrentOverviewListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentOverviewListQueryVariables> | ReactiveFunction<Types.UserCurrentOverviewListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>(UserCurrentOverviewListDocument, variables, options);
}
export type UserCurrentOverviewListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>;