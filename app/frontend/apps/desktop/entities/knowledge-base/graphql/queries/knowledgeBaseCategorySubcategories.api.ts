import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseCategoryPolicyFragmentDoc } from '../fragments/knowledgeBaseCategoryPolicy.api';
import { KnowledgeBaseCategoryPreInfoFragmentDoc } from '../fragments/knowledgeBaseCategoryPreInfo.api';
import { KnowledgeBaseCategoryGridAttributesFragmentDoc } from '../fragments/knowledgeBaseCategoryGridAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseCategorySubcategoriesDocument = gql`
    query knowledgeBaseCategorySubcategories($categoryId: ID, $locale: String, $sortingMode: EnumKnowledgeBaseSortingMode) {
  knowledgeBaseCategorySubcategories(
    categoryId: $categoryId
    locale: $locale
    sortingMode: $sortingMode
  ) {
    category {
      id
      isVisiblePublicly(locale: $locale)
      translation(locale: $locale) {
        id
        title
        kbLocale {
          id
          systemLocale {
            locale
          }
        }
      }
      isDeletable
      categorySortingMode
      answerSortingMode
      ...knowledgeBaseCategoryPolicy
      ...knowledgeBaseCategoryPreInfo
    }
    subcategories {
      ...knowledgeBaseCategoryGridAttributes
    }
  }
}
    ${KnowledgeBaseCategoryPolicyFragmentDoc}
${KnowledgeBaseCategoryPreInfoFragmentDoc}
${KnowledgeBaseCategoryGridAttributesFragmentDoc}`;
export function useKnowledgeBaseCategorySubcategoriesQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>(KnowledgeBaseCategorySubcategoriesDocument, options);
}
export function useKnowledgeBaseCategorySubcategoriesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>(KnowledgeBaseCategorySubcategoriesDocument, options);
}
export type KnowledgeBaseCategorySubcategoriesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>;