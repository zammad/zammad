import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountAvatarAddDocument = gql`
    mutation accountAvatarAdd($images: AvatarInput!) {
  accountAvatarAdd(images: $images) {
    avatar {
      id
      default
      deletable
      initial
      imageFull
      imageResize
      createdAt
      updatedAt
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountAvatarAddMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountAvatarAddMutation, Types.AccountAvatarAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountAvatarAddMutation, Types.AccountAvatarAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountAvatarAddMutation, Types.AccountAvatarAddMutationVariables>(AccountAvatarAddDocument, options);
}
export type AccountAvatarAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountAvatarAddMutation, Types.AccountAvatarAddMutationVariables>;