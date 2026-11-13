import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerPreInfoFragmentDoc } from '../fragments/knowledgeBaseAnswerPreInfo.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswersDocument = gql`
    query knowledgeBaseAnswers($categoryId: ID!, $locale: String, $pageSize: Int = 30, $cursor: String, $sortingMode: EnumKnowledgeBaseSortingMode) {
  knowledgeBaseAnswers(
    categoryId: $categoryId
    locale: $locale
    first: $pageSize
    after: $cursor
    sortingMode: $sortingMode
  ) {
    totalCount
    edges {
      node {
        id
        visibility
        position
        ...knowledgeBaseAnswerPreInfo
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
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    ${KnowledgeBaseAnswerPreInfoFragmentDoc}`;
export function useKnowledgeBaseAnswersQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>(KnowledgeBaseAnswersDocument, options);
}
export function useKnowledgeBaseAnswersLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>(KnowledgeBaseAnswersDocument, options);
}
export type KnowledgeBaseAnswersQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>;