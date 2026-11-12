import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerSuggestionsDocument = gql`
    query knowledgeBaseAnswerSuggestions($query: String!) {
  knowledgeBaseAnswerSuggestions(query: $query) {
    id
    title
    maybeLocale
    categoryTreeTranslation {
      id
      title
    }
  }
}
    `;
export function useKnowledgeBaseAnswerSuggestionsQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>(KnowledgeBaseAnswerSuggestionsDocument, options);
}
export function useKnowledgeBaseAnswerSuggestionsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>(KnowledgeBaseAnswerSuggestionsDocument, options);
}
export type KnowledgeBaseAnswerSuggestionsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>;