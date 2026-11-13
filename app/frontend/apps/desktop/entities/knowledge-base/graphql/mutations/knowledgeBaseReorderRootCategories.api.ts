import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useKnowledgeBaseReorderRootCategoriesMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables>(KnowledgeBaseReorderRootCategoriesDocument, options);
}
export type KnowledgeBaseReorderRootCategoriesMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables>;