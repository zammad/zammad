import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentAvatarSelectDocument = gql`
    mutation userCurrentAvatarSelect($id: ID!) {
  userCurrentAvatarSelect(id: $id) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentAvatarSelectMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables>(UserCurrentAvatarSelectDocument, options);
}
export type UserCurrentAvatarSelectMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables>;