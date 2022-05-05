import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LogoutDocument = gql`
    mutation logout {
  logout {
    success
  }
}
    `;
export function useLogoutMutation(options: VueApolloComposable.UseMutationOptions<Types.LogoutMutation, Types.LogoutMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.LogoutMutation, Types.LogoutMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.LogoutMutation, Types.LogoutMutationVariables>(LogoutDocument, options);
}
export type LogoutMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.LogoutMutation, Types.LogoutMutationVariables>;