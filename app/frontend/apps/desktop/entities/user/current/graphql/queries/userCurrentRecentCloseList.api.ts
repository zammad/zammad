import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentRecentCloseListDocument = gql`
    query userCurrentRecentCloseList($limit: Int) {
  userCurrentRecentCloseList(limit: $limit) {
    ... on Ticket {
      id
      internalId
      title
      number
      state {
        id
        name
      }
      priority {
        id
        name
        defaultCreate
        uiColor
      }
      stateColorCode
    }
    ... on User {
      id
      internalId
      fullname
      active
    }
    ... on Organization {
      id
      internalId
      name
      active
    }
  }
}
    `;
export function useUserCurrentRecentCloseListQuery(variables: Types.UserCurrentRecentCloseListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentRecentCloseListQueryVariables> | ReactiveFunction<Types.UserCurrentRecentCloseListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>(UserCurrentRecentCloseListDocument, variables, options);
}
export function useUserCurrentRecentCloseListLazyQuery(variables: Types.UserCurrentRecentCloseListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentRecentCloseListQueryVariables> | ReactiveFunction<Types.UserCurrentRecentCloseListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>(UserCurrentRecentCloseListDocument, variables, options);
}
export type UserCurrentRecentCloseListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>;