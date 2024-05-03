import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentAvatarListDocument = gql`
    query userCurrentAvatarList {
  userCurrentAvatarList {
    id
    default
    deletable
    initial
    imageHash
    createdAt
    updatedAt
  }
}
    `;
export function useUserCurrentAvatarListQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>(UserCurrentAvatarListDocument, {}, options);
}
export function useUserCurrentAvatarListLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>(UserCurrentAvatarListDocument, {}, options);
}
export type UserCurrentAvatarListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>;