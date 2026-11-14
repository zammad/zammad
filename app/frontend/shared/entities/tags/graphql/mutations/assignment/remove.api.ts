import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TagAssignmentRemoveDocument = gql`
    mutation tagAssignmentRemove($objectId: ID!, $tag: String!) {
  tagAssignmentRemove(objectId: $objectId, tag: $tag) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTagAssignmentRemoveMutation(options: VueApolloComposable.useMutation.Options<Types.TagAssignmentRemoveMutation, Types.TagAssignmentRemoveMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TagAssignmentRemoveMutation, Types.TagAssignmentRemoveMutationVariables>(TagAssignmentRemoveDocument, options);
}
export type TagAssignmentRemoveMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TagAssignmentRemoveMutation, Types.TagAssignmentRemoveMutationVariables>;