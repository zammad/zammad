import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserPasswordResetSendDocument = gql`
    mutation userPasswordResetSend($username: String!) {
  userPasswordResetSend(username: $username) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserPasswordResetSendMutation(options: VueApolloComposable.UseMutationOptions<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables>(UserPasswordResetSendDocument, options);
}
export type UserPasswordResetSendMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables>;