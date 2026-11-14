import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTwoFactorGetMethodConfigurationDocument = gql`
    query userCurrentTwoFactorGetMethodConfiguration($methodName: String!, $token: String!) {
  userCurrentTwoFactorGetMethodConfiguration(
    methodName: $methodName
    token: $token
  )
}
    `;
export function useUserCurrentTwoFactorGetMethodConfigurationQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>(UserCurrentTwoFactorGetMethodConfigurationDocument, options);
}
export function useUserCurrentTwoFactorGetMethodConfigurationLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>(UserCurrentTwoFactorGetMethodConfigurationDocument, options);
}
export type UserCurrentTwoFactorGetMethodConfigurationQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>;