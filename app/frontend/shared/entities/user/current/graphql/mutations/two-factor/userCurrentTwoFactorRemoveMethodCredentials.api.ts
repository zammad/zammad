import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTwoFactorRemoveMethodCredentialsDocument = gql`
    mutation userCurrentTwoFactorRemoveMethodCredentials($methodName: String!, $credentialId: String!) {
  userCurrentTwoFactorRemoveMethodCredentials(
    methodName: $methodName
    credentialId: $credentialId
  ) {
    success
  }
}
    `;
export function useUserCurrentTwoFactorRemoveMethodCredentialsMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorRemoveMethodCredentialsMutation, Types.UserCurrentTwoFactorRemoveMethodCredentialsMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorRemoveMethodCredentialsMutation, Types.UserCurrentTwoFactorRemoveMethodCredentialsMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorRemoveMethodCredentialsMutation, Types.UserCurrentTwoFactorRemoveMethodCredentialsMutationVariables>(UserCurrentTwoFactorRemoveMethodCredentialsDocument, options);
}
export type UserCurrentTwoFactorRemoveMethodCredentialsMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTwoFactorRemoveMethodCredentialsMutation, Types.UserCurrentTwoFactorRemoveMethodCredentialsMutationVariables>;