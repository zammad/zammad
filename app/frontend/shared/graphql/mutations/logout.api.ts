import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const LogoutDocument = gql`
    mutation logout {
  logout {
    success
    externalLogoutUrl
  }
}
    `;
export function useLogoutMutation(options: VueApolloComposable.useMutation.Options<Types.LogoutMutation, Types.LogoutMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.LogoutMutation, Types.LogoutMutationVariables>(LogoutDocument, options);
}
export type LogoutMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.LogoutMutation, Types.LogoutMutationVariables>;