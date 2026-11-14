import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentAvatarAddDocument = gql`
    mutation userCurrentAvatarAdd($images: AvatarInput!) {
  userCurrentAvatarAdd(images: $images) {
    avatar {
      id
      default
      deletable
      initial
      imageFull
      imageResize
      imageHash
      createdAt
      updatedAt
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentAvatarAddMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables>(UserCurrentAvatarAddDocument, options);
}
export type UserCurrentAvatarAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables>;