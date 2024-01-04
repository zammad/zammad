import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserSignupResendDocument = gql`
    mutation userSignupResend($email: String!) {
  userSignupResend(email: $email) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserSignupResendMutation(options: VueApolloComposable.UseMutationOptions<Types.UserSignupResendMutation, Types.UserSignupResendMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserSignupResendMutation, Types.UserSignupResendMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserSignupResendMutation, Types.UserSignupResendMutationVariables>(UserSignupResendDocument, options);
}
export type UserSignupResendMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserSignupResendMutation, Types.UserSignupResendMutationVariables>;