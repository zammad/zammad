import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserPasswordResetVerifyDocument = gql`
    mutation userPasswordResetVerify($token: String!) {
  userPasswordResetVerify(token: $token) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserPasswordResetVerifyMutation(options: VueApolloComposable.useMutation.Options<Types.UserPasswordResetVerifyMutation, Types.UserPasswordResetVerifyMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserPasswordResetVerifyMutation, Types.UserPasswordResetVerifyMutationVariables>(UserPasswordResetVerifyDocument, options);
}
export type UserPasswordResetVerifyMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserPasswordResetVerifyMutation, Types.UserPasswordResetVerifyMutationVariables>;