import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AdminPasswordAuthSendDocument = gql`
    mutation adminPasswordAuthSend($login: String!) {
  adminPasswordAuthSend(login: $login) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAdminPasswordAuthSendMutation(options: VueApolloComposable.UseMutationOptions<Types.AdminPasswordAuthSendMutation, Types.AdminPasswordAuthSendMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AdminPasswordAuthSendMutation, Types.AdminPasswordAuthSendMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AdminPasswordAuthSendMutation, Types.AdminPasswordAuthSendMutationVariables>(AdminPasswordAuthSendDocument, options);
}
export type AdminPasswordAuthSendMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AdminPasswordAuthSendMutation, Types.AdminPasswordAuthSendMutationVariables>;