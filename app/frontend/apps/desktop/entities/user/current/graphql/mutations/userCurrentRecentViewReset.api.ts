import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentRecentViewResetDocument = gql`
    mutation userCurrentRecentViewReset {
  userCurrentRecentViewReset {
    success
  }
}
    `;
export function useUserCurrentRecentViewResetMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentRecentViewResetMutation, Types.UserCurrentRecentViewResetMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentRecentViewResetMutation, Types.UserCurrentRecentViewResetMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentRecentViewResetMutation, Types.UserCurrentRecentViewResetMutationVariables>(UserCurrentRecentViewResetDocument, options);
}
export type UserCurrentRecentViewResetMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentRecentViewResetMutation, Types.UserCurrentRecentViewResetMutationVariables>;