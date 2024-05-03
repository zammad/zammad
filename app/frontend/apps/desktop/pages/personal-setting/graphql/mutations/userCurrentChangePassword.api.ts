import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentChangePasswordDocument = gql`
    mutation userCurrentChangePassword($currentPassword: String!, $newPassword: String!) {
  userCurrentChangePassword(
    currentPassword: $currentPassword
    newPassword: $newPassword
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentChangePasswordMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables>(UserCurrentChangePasswordDocument, options);
}
export type UserCurrentChangePasswordMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables>;