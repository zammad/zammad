import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserCurrentAvatarAddMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables>(UserCurrentAvatarAddDocument, options);
}
export type UserCurrentAvatarAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables>;