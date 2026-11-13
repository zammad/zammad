import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseSearchDocument = gql`
    query knowledgeBaseSearch($query: String!, $entity: EnumKnowledgeBaseSearchEntity!, $categoryId: ID, $locale: String, $pageSize: Int = 30, $cursor: String) {
  knowledgeBaseSearch(
    query: $query
    entity: $entity
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
export function useKnowledgeBaseSearchQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>(KnowledgeBaseSearchDocument, options);
}
export function useKnowledgeBaseSearchLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>(KnowledgeBaseSearchDocument, options);
}
export type KnowledgeBaseSearchQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>;