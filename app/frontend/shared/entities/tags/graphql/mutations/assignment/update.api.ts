import * as Types from '../../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTagAssignmentUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TagAssignmentUpdateMutation, Types.TagAssignmentUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TagAssignmentUpdateMutation, Types.TagAssignmentUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TagAssignmentUpdateMutation, Types.TagAssignmentUpdateMutationVariables>(TagAssignmentUpdateDocument, options);
}
export type TagAssignmentUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TagAssignmentUpdateMutation, Types.TagAssignmentUpdateMutationVariables>;