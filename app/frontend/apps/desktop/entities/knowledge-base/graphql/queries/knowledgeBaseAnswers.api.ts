import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswersDocument = gql`
    query knowledgeBaseAnswers($categoryId: ID!, $locale: String, $pageSize: Int = 30, $cursor: String) {
  knowledgeBaseAnswers(
    categoryId: $categoryId
    locale: $locale
    first: $pageSize
    after: $cursor
  ) {
    totalCount
    edges {
      node {
        id
        title
        visibility
        translationMissing
        position
      }
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    `;
export function useKnowledgeBaseAnswersQuery(variables: Types.KnowledgeBaseAnswersQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswersQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswersQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>(KnowledgeBaseAnswersDocument, variables, options);
}
export function useKnowledgeBaseAnswersLazyQuery(variables?: Types.KnowledgeBaseAnswersQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswersQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswersQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>(KnowledgeBaseAnswersDocument, variables, options);
}
export type KnowledgeBaseAnswersQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseAnswersQuery, Types.KnowledgeBaseAnswersQueryVariables>;