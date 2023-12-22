import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AdminPasswordAuthVerifyDocument = gql`
    mutation adminPasswordAuthVerify($token: String!) {
  adminPasswordAuthVerify(token: $token) {
    login
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAdminPasswordAuthVerifyMutation(options: VueApolloComposable.UseMutationOptions<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables>(AdminPasswordAuthVerifyDocument, options);
}
export type AdminPasswordAuthVerifyMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables>;