import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchKnowledgeBaseAnswerDocument = gql`
    query autocompleteSearchKnowledgeBaseAnswer($input: AutocompleteSearchKnowledgeBaseAnswerInput!) {
  autocompleteSearchKnowledgeBaseAnswer(input: $input) {
    value
    label
    heading
    visibility
  }
}
    `;
export function useAutocompleteSearchKnowledgeBaseAnswerQuery(variables: Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables> | ReactiveFunction<Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>(AutocompleteSearchKnowledgeBaseAnswerDocument, variables, options);
}
export function useAutocompleteSearchKnowledgeBaseAnswerLazyQuery(variables?: Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables> | ReactiveFunction<Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>(AutocompleteSearchKnowledgeBaseAnswerDocument, variables, options);
}
export type AutocompleteSearchKnowledgeBaseAnswerQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>;