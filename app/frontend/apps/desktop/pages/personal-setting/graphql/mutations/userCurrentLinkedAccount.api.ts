import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentRemoveLinkedAccountDocument = gql`
    mutation userCurrentRemoveLinkedAccount($provider: EnumAuthenticationProvider!, $uid: String!) {
  userCurrentRemoveLinkedAccount(provider: $provider, uid: $uid) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentRemoveLinkedAccountMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentRemoveLinkedAccountMutation, Types.UserCurrentRemoveLinkedAccountMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentRemoveLinkedAccountMutation, Types.UserCurrentRemoveLinkedAccountMutationVariables>(UserCurrentRemoveLinkedAccountDocument, options);
}
export type UserCurrentRemoveLinkedAccountMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentRemoveLinkedAccountMutation, Types.UserCurrentRemoveLinkedAccountMutationVariables>;