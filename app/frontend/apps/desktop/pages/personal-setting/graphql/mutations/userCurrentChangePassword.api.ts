import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentChangePasswordMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables>(UserCurrentChangePasswordDocument, options);
}
export type UserCurrentChangePasswordMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables>;