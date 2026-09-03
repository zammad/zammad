import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseSearchDocument = gql`
    query knowledgeBaseSearch($query: String!, $categoryId: ID, $locale: String, $pageSize: Int = 30, $cursor: String) {
  knowledgeBaseSearch(
    query: $query
    categoryId: $categoryId
    locale: $locale
    first: $pageSize
    after: $cursor
  ) {
    totalCount
    edges {
      node {
        item {
          ... on KnowledgeBaseAnswer {
            id
            visibility
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
          }
          ... on KnowledgeBaseCategory {
            id
            translation(locale: $locale) {
              id
              title
            }
            categoryIcon
            iconSet
            visibility(locale: $locale)
          }
        }
        titlePreview {
          text
          highlight
        }
        bodyPreview {
          text
          highlight
        }
        categoryPath {
          id
          title(locale: $locale)
        }
      }
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    `;
export function useKnowledgeBaseSearchQuery(variables: Types.KnowledgeBaseSearchQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseSearchQueryVariables> | ReactiveFunction<Types.KnowledgeBaseSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>(KnowledgeBaseSearchDocument, variables, options);
}
export function useKnowledgeBaseSearchLazyQuery(variables?: Types.KnowledgeBaseSearchQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseSearchQueryVariables> | ReactiveFunction<Types.KnowledgeBaseSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>(KnowledgeBaseSearchDocument, variables, options);
}
export type KnowledgeBaseSearchQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>;