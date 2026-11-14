import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentAvatarDeleteDocument = gql`
    mutation userCurrentAvatarDelete($id: ID!) {
  userCurrentAvatarDelete(id: $id) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentAvatarDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentAvatarDeleteMutation, Types.UserCurrentAvatarDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAvatarDeleteMutation, Types.UserCurrentAvatarDeleteMutationVariables>(UserCurrentAvatarDeleteDocument, options);
}
export type UserCurrentAvatarDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentAvatarDeleteMutation, Types.UserCurrentAvatarDeleteMutationVariables>;