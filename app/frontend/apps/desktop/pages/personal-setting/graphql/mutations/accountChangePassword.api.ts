import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountChangePasswordDocument = gql`
    mutation accountChangePassword($currentPassword: String!, $newPassword: String!) {
  accountChangePassword(
    currentPassword: $currentPassword
    newPassword: $newPassword
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountChangePasswordMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountChangePasswordMutation, Types.AccountChangePasswordMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountChangePasswordMutation, Types.AccountChangePasswordMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountChangePasswordMutation, Types.AccountChangePasswordMutationVariables>(AccountChangePasswordDocument, options);
}
export type AccountChangePasswordMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountChangePasswordMutation, Types.AccountChangePasswordMutationVariables>;