import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserPasswordResetUpdateDocument = gql`
    mutation userPasswordResetUpdate($token: String!, $password: String!) {
  userPasswordResetUpdate(token: $token, password: $password) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserPasswordResetUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserPasswordResetUpdateMutation, Types.UserPasswordResetUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserPasswordResetUpdateMutation, Types.UserPasswordResetUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserPasswordResetUpdateMutation, Types.UserPasswordResetUpdateMutationVariables>(UserPasswordResetUpdateDocument, options);
}
export type UserPasswordResetUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserPasswordResetUpdateMutation, Types.UserPasswordResetUpdateMutationVariables>;