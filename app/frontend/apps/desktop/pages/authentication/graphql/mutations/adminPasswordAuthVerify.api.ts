import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AdminPasswordAuthVerifyDocument = gql`
    mutation adminPasswordAuthVerify($token: String!) {
  adminPasswordAuthVerify(token: $token) {
    login
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAdminPasswordAuthVerifyMutation(options: VueApolloComposable.useMutation.Options<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables>(AdminPasswordAuthVerifyDocument, options);
}
export type AdminPasswordAuthVerifyMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables>;