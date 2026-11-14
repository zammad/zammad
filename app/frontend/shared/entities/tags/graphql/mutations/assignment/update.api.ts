import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TagAssignmentUpdateDocument = gql`
    mutation tagAssignmentUpdate($objectId: ID!, $tags: [String!]!) {
  tagAssignmentUpdate(objectId: $objectId, tags: $tags) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTagAssignmentUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.TagAssignmentUpdateMutation, Types.TagAssignmentUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TagAssignmentUpdateMutation, Types.TagAssignmentUpdateMutationVariables>(TagAssignmentUpdateDocument, options);
}
export type TagAssignmentUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TagAssignmentUpdateMutation, Types.TagAssignmentUpdateMutationVariables>;