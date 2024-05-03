import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTwoFactorVerifyMethodConfigurationDocument = gql`
    mutation userCurrentTwoFactorVerifyMethodConfiguration($methodName: EnumTwoFactorAuthenticationMethod!, $payload: JSON!, $configuration: JSON!) {
  userCurrentTwoFactorVerifyMethodConfiguration(
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
export function useUserCurrentTwoFactorVerifyMethodConfigurationMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables>(UserCurrentTwoFactorVerifyMethodConfigurationDocument, options);
}
export type UserCurrentTwoFactorVerifyMethodConfigurationMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables>;