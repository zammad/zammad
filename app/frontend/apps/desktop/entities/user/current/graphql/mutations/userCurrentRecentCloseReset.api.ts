import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentRecentCloseResetDocument = gql`
    mutation userCurrentRecentCloseReset {
  userCurrentRecentCloseReset {
    success
  }
}
    `;
export function useUserCurrentRecentCloseResetMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables>(UserCurrentRecentCloseResetDocument, options);
}
export type UserCurrentRecentCloseResetMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables>;