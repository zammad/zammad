import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserPasswordResetSendMutation(options: VueApolloComposable.useMutation.Options<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables>(UserPasswordResetSendDocument, options);
}
export type UserPasswordResetSendMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables>;