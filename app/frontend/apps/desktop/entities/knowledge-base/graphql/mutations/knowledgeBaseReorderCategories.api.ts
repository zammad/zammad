import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseReorderCategoriesDocument = gql`
    mutation knowledgeBaseReorderCategories($parentCategoryId: ID!, $sortingMode: EnumKnowledgeBaseSortingMode!, $categoryIds: [ID!]) {
  knowledgeBaseReorderCategories(
    parentCategoryId: $parentCategoryId
    sortingMode: $sortingMode
    categoryIds: $categoryIds
  ) {
    category {
      id
      categorySortingMode
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseReorderCategoriesMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables>(KnowledgeBaseReorderCategoriesDocument, options);
}
export type KnowledgeBaseReorderCategoriesMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables>;