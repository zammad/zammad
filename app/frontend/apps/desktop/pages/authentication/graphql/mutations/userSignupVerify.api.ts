import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SessionFragmentDoc } from '../../../../../../shared/graphql/fragments/session.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserSignupVerifyDocument = gql`
    mutation userSignupVerify($token: String!) {
  userSignupVerify(token: $token) {
    session {
      ...session
    }
    errors {
      ...errors
    }
  }
}
    ${SessionFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserSignupVerifyMutation(options: VueApolloComposable.UseMutationOptions<Types.UserSignupVerifyMutation, Types.UserSignupVerifyMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserSignupVerifyMutation, Types.UserSignupVerifyMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserSignupVerifyMutation, Types.UserSignupVerifyMutationVariables>(UserSignupVerifyDocument, options);
}
export type UserSignupVerifyMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserSignupVerifyMutation, Types.UserSignupVerifyMutationVariables>;