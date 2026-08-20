import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseCategoryDeleteDocument = gql`
    mutation knowledgeBaseCategoryDelete($categoryId: ID!) {
  knowledgeBaseCategoryDelete(categoryId: $categoryId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseCategoryDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryDeleteMutation, Types.KnowledgeBaseCategoryDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryDeleteMutation, Types.KnowledgeBaseCategoryDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseCategoryDeleteMutation, Types.KnowledgeBaseCategoryDeleteMutationVariables>(KnowledgeBaseCategoryDeleteDocument, options);
}
export type KnowledgeBaseCategoryDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseCategoryDeleteMutation, Types.KnowledgeBaseCategoryDeleteMutationVariables>;