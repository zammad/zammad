import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useKnowledgeBaseReorderCategoriesMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables>(KnowledgeBaseReorderCategoriesDocument, options);
}
export type KnowledgeBaseReorderCategoriesMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables>;