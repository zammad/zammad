import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentAvatarListQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>(UserCurrentAvatarListDocument, options);
}
export function useUserCurrentAvatarListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>(UserCurrentAvatarListDocument, options);
}
export type UserCurrentAvatarListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>;