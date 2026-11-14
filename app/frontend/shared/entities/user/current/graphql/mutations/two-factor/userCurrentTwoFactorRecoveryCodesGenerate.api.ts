import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTwoFactorRecoveryCodesGenerateDocument = gql`
    mutation userCurrentTwoFactorRecoveryCodesGenerate($token: String!) {
  userCurrentTwoFactorRecoveryCodesGenerate(token: $token) {
    recoveryCodes
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTwoFactorRecoveryCodesGenerateMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables>(UserCurrentTwoFactorRecoveryCodesGenerateDocument, options);
}
export type UserCurrentTwoFactorRecoveryCodesGenerateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables>;