import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseCategoryPolicyFragmentDoc } from '../fragments/knowledgeBaseCategoryPolicy.api';
import { KnowledgeBaseCategoryPreInfoFragmentDoc } from '../fragments/knowledgeBaseCategoryPreInfo.api';
import { KnowledgeBaseCategoryGridAttributesFragmentDoc } from '../fragments/knowledgeBaseCategoryGridAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useKnowledgeBaseCategorySubcategoriesQuery(variables: Types.KnowledgeBaseCategorySubcategoriesQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseCategorySubcategoriesQueryVariables> | ReactiveFunction<Types.KnowledgeBaseCategorySubcategoriesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>(KnowledgeBaseCategorySubcategoriesDocument, variables, options);
}
export function useKnowledgeBaseCategorySubcategoriesLazyQuery(variables: Types.KnowledgeBaseCategorySubcategoriesQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseCategorySubcategoriesQueryVariables> | ReactiveFunction<Types.KnowledgeBaseCategorySubcategoriesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>(KnowledgeBaseCategorySubcategoriesDocument, variables, options);
}
export type KnowledgeBaseCategorySubcategoriesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>;