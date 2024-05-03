import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTwoFactorRecoveryCodesGenerateDocument = gql`
    mutation userCurrentTwoFactorRecoveryCodesGenerate {
  userCurrentTwoFactorRecoveryCodesGenerate {
    recoveryCodes
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTwoFactorRecoveryCodesGenerateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables>(UserCurrentTwoFactorRecoveryCodesGenerateDocument, options);
}
export type UserCurrentTwoFactorRecoveryCodesGenerateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables>;