import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentAvatarActiveQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>(UserCurrentAvatarActiveDocument, options);
}
export function useUserCurrentAvatarActiveLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>(UserCurrentAvatarActiveDocument, options);
}
export type UserCurrentAvatarActiveQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>;