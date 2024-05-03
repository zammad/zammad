import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserCurrentTwoFactorConfigurationQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>(UserCurrentTwoFactorConfigurationDocument, {}, options);
}
export function useUserCurrentTwoFactorConfigurationLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>(UserCurrentTwoFactorConfigurationDocument, {}, options);
}
export type UserCurrentTwoFactorConfigurationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>;