import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountTwoFactorConfigurationDocument = gql`
    query accountTwoFactorConfiguration {
  accountTwoFactorConfiguration {
    recoveryCodesExist
    enabledAuthenticationMethods {
      configured
      default
      authenticationMethod
    }
  }
}
    `;
export function useAccountTwoFactorConfigurationQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>(AccountTwoFactorConfigurationDocument, {}, options);
}
export function useAccountTwoFactorConfigurationLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>(AccountTwoFactorConfigurationDocument, {}, options);
}
export type AccountTwoFactorConfigurationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>;