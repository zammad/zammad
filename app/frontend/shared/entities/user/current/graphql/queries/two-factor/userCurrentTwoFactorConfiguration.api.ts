import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTwoFactorConfigurationDocument = gql`
    query userCurrentTwoFactorConfiguration {
  userCurrentTwoFactorConfiguration {
    recoveryCodesExist
    enabledAuthenticationMethods {
      configured
      default
      authenticationMethod
    }
  }
}
    `;
export function useUserCurrentTwoFactorConfigurationQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>(UserCurrentTwoFactorConfigurationDocument, options);
}
export function useUserCurrentTwoFactorConfigurationLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>(UserCurrentTwoFactorConfigurationDocument, options);
}
export type UserCurrentTwoFactorConfigurationQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>;