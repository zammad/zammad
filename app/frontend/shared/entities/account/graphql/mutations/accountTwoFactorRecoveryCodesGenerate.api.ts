import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountTwoFactorRecoveryCodesGenerateDocument = gql`
    mutation accountTwoFactorRecoveryCodesGenerate {
  accountTwoFactorRecoveryCodesGenerate {
    recoveryCodes
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountTwoFactorRecoveryCodesGenerateMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorRecoveryCodesGenerateMutation, Types.AccountTwoFactorRecoveryCodesGenerateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorRecoveryCodesGenerateMutation, Types.AccountTwoFactorRecoveryCodesGenerateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountTwoFactorRecoveryCodesGenerateMutation, Types.AccountTwoFactorRecoveryCodesGenerateMutationVariables>(AccountTwoFactorRecoveryCodesGenerateDocument, options);
}
export type AccountTwoFactorRecoveryCodesGenerateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountTwoFactorRecoveryCodesGenerateMutation, Types.AccountTwoFactorRecoveryCodesGenerateMutationVariables>;