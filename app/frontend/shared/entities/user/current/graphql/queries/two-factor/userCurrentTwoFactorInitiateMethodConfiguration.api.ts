import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTwoFactorInitiateMethodConfigurationDocument = gql`
    query userCurrentTwoFactorInitiateMethodConfiguration($methodName: EnumTwoFactorAuthenticationMethod!, $token: String!) {
  userCurrentTwoFactorInitiateMethodConfiguration(
    methodName: $methodName
    token: $token
  )
}
    `;
export function useUserCurrentTwoFactorInitiateMethodConfigurationQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery, Types.UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery, Types.UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables>(UserCurrentTwoFactorInitiateMethodConfigurationDocument, options);
}
export function useUserCurrentTwoFactorInitiateMethodConfigurationLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery, Types.UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery, Types.UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables>(UserCurrentTwoFactorInitiateMethodConfigurationDocument, options);
}
export type UserCurrentTwoFactorInitiateMethodConfigurationQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery, Types.UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables>;