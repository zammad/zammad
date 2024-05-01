import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountTwoFactorGetMethodConfigurationDocument = gql`
    query accountTwoFactorGetMethodConfiguration($methodName: String!) {
  accountTwoFactorGetMethodConfiguration(methodName: $methodName)
}
    `;
export function useAccountTwoFactorGetMethodConfigurationQuery(variables: Types.AccountTwoFactorGetMethodConfigurationQueryVariables | VueCompositionApi.Ref<Types.AccountTwoFactorGetMethodConfigurationQueryVariables> | ReactiveFunction<Types.AccountTwoFactorGetMethodConfigurationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>(AccountTwoFactorGetMethodConfigurationDocument, variables, options);
}
export function useAccountTwoFactorGetMethodConfigurationLazyQuery(variables?: Types.AccountTwoFactorGetMethodConfigurationQueryVariables | VueCompositionApi.Ref<Types.AccountTwoFactorGetMethodConfigurationQueryVariables> | ReactiveFunction<Types.AccountTwoFactorGetMethodConfigurationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>(AccountTwoFactorGetMethodConfigurationDocument, variables, options);
}
export type AccountTwoFactorGetMethodConfigurationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>;