import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentAvatarActiveDocument = gql`
    query userCurrentAvatarActive {
  userCurrentAvatarActive {
    id
    default
    deletable
    initial
    imageFull
    imageResize
    createdAt
    updatedAt
  }
}
    `;
export function useUserCurrentAvatarActiveQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>(UserCurrentAvatarActiveDocument, {}, options);
}
export function useUserCurrentAvatarActiveLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>(UserCurrentAvatarActiveDocument, {}, options);
}
export type UserCurrentAvatarActiveQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>;