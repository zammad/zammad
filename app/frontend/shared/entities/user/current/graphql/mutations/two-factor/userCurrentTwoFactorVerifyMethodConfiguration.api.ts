import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTwoFactorVerifyMethodConfigurationDocument = gql`
    mutation userCurrentTwoFactorVerifyMethodConfiguration($methodName: EnumTwoFactorAuthenticationMethod!, $token: String!, $payload: JSON!, $configuration: JSON!) {
  userCurrentTwoFactorVerifyMethodConfiguration(
    methodName: $methodName
    token: $token
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
export function useUserCurrentTwoFactorVerifyMethodConfigurationMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables>(UserCurrentTwoFactorVerifyMethodConfigurationDocument, options);
}
export type UserCurrentTwoFactorVerifyMethodConfigurationMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables>;