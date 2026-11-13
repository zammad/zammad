import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentRecentCloseResetDocument = gql`
    mutation userCurrentRecentCloseReset {
  userCurrentRecentCloseReset {
    success
  }
}
    `;
export function useUserCurrentRecentCloseResetMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables>(UserCurrentRecentCloseResetDocument, options);
}
export type UserCurrentRecentCloseResetMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables>;