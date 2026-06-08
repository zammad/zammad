import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useKnowledgeBaseAnswerSuggestionsQuery(variables: Types.KnowledgeBaseAnswerSuggestionsQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerSuggestionsQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>(KnowledgeBaseAnswerSuggestionsDocument, variables, options);
}
export function useKnowledgeBaseAnswerSuggestionsLazyQuery(variables?: Types.KnowledgeBaseAnswerSuggestionsQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerSuggestionsQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>(KnowledgeBaseAnswerSuggestionsDocument, variables, options);
}
export type KnowledgeBaseAnswerSuggestionsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>;