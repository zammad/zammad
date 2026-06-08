import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserNoteUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables>(UserNoteUpdateDocument, options);
}
export type UserNoteUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables>;