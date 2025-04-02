import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentRecentViewListDocument = gql`
    query userCurrentRecentViewList($limit: Int) {
  userCurrentRecentViewList(limit: $limit) {
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
export function useUserCurrentRecentViewListQuery(variables: Types.UserCurrentRecentViewListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentRecentViewListQueryVariables> | ReactiveFunction<Types.UserCurrentRecentViewListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>(UserCurrentRecentViewListDocument, variables, options);
}
export function useUserCurrentRecentViewListLazyQuery(variables: Types.UserCurrentRecentViewListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentRecentViewListQueryVariables> | ReactiveFunction<Types.UserCurrentRecentViewListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>(UserCurrentRecentViewListDocument, variables, options);
}
export type UserCurrentRecentViewListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>;