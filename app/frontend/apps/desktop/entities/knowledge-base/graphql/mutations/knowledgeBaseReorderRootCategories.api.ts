import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseReorderRootCategoriesDocument = gql`
    mutation knowledgeBaseReorderRootCategories($sortingMode: EnumKnowledgeBaseSortingMode!, $categoryIds: [ID!]) {
  knowledgeBaseReorderRootCategories(
    sortingMode: $sortingMode
    categoryIds: $categoryIds
  ) {
    knowledgeBase {
      id
      categorySortingMode
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseReorderRootCategoriesMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables>(KnowledgeBaseReorderRootCategoriesDocument, options);
}
export type KnowledgeBaseReorderRootCategoriesMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables>;