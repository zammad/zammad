import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountAvatarListDocument = gql`
    query accountAvatarList {
  accountAvatarList {
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
export function useAccountAvatarListQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>(AccountAvatarListDocument, {}, options);
}
export function useAccountAvatarListLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>(AccountAvatarListDocument, {}, options);
}
export type AccountAvatarListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>;