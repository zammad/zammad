import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserNoteUpdateDocument = gql`
    mutation userNoteUpdate($id: ID!, $note: String!) {
  userNoteUpdate(id: $id, note: $note) {
    user {
      note
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserNoteUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables>(UserNoteUpdateDocument, options);
}
export type UserNoteUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables>;