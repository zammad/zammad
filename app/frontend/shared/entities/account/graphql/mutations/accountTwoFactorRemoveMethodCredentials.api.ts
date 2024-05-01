import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountTwoFactorRemoveMethodCredentialsDocument = gql`
    mutation accountTwoFactorRemoveMethodCredentials($methodName: String!, $credentialId: String!) {
  accountTwoFactorRemoveMethodCredentials(
    methodName: $methodName
    credentialId: $credentialId
  ) {
    success
  }
}
    `;
export function useAccountTwoFactorRemoveMethodCredentialsMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorRemoveMethodCredentialsMutation, Types.AccountTwoFactorRemoveMethodCredentialsMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorRemoveMethodCredentialsMutation, Types.AccountTwoFactorRemoveMethodCredentialsMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountTwoFactorRemoveMethodCredentialsMutation, Types.AccountTwoFactorRemoveMethodCredentialsMutationVariables>(AccountTwoFactorRemoveMethodCredentialsDocument, options);
}
export type AccountTwoFactorRemoveMethodCredentialsMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountTwoFactorRemoveMethodCredentialsMutation, Types.AccountTwoFactorRemoveMethodCredentialsMutationVariables>;