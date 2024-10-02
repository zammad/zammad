import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TagAssignmentAddDocument = gql`
    mutation tagAssignmentAdd($objectId: ID!, $tag: String!) {
  tagAssignmentAdd(objectId: $objectId, tag: $tag) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTagAssignmentAddMutation(options: VueApolloComposable.UseMutationOptions<Types.TagAssignmentAddMutation, Types.TagAssignmentAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TagAssignmentAddMutation, Types.TagAssignmentAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TagAssignmentAddMutation, Types.TagAssignmentAddMutationVariables>(TagAssignmentAddDocument, options);
}
export type TagAssignmentAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TagAssignmentAddMutation, Types.TagAssignmentAddMutationVariables>;