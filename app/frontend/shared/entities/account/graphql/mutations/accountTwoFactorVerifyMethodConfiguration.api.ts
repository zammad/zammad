import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountTwoFactorVerifyMethodConfigurationDocument = gql`
    mutation accountTwoFactorVerifyMethodConfiguration($methodName: EnumTwoFactorAuthenticationMethod!, $payload: JSON!, $configuration: JSON!) {
  accountTwoFactorVerifyMethodConfiguration(
    methodName: $methodName
    payload: $payload
    configuration: $configuration
  ) {
    recoveryCodes
    errors {
      message
      field
    }
  }
}
    `;
export function useAccountTwoFactorVerifyMethodConfigurationMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorVerifyMethodConfigurationMutation, Types.AccountTwoFactorVerifyMethodConfigurationMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorVerifyMethodConfigurationMutation, Types.AccountTwoFactorVerifyMethodConfigurationMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountTwoFactorVerifyMethodConfigurationMutation, Types.AccountTwoFactorVerifyMethodConfigurationMutationVariables>(AccountTwoFactorVerifyMethodConfigurationDocument, options);
}
export type AccountTwoFactorVerifyMethodConfigurationMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountTwoFactorVerifyMethodConfigurationMutation, Types.AccountTwoFactorVerifyMethodConfigurationMutationVariables>;