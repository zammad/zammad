import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchKnowledgeBaseAnswerDocument = gql`
    query autocompleteSearchKnowledgeBaseAnswer($input: AutocompleteSearchKnowledgeBaseAnswerInput!) {
  autocompleteSearchKnowledgeBaseAnswer(input: $input) {
    value
    label
    heading
    visibility
    url
  }
}
    `;
export function useAutocompleteSearchKnowledgeBaseAnswerQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>(AutocompleteSearchKnowledgeBaseAnswerDocument, options);
}
export function useAutocompleteSearchKnowledgeBaseAnswerLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>(AutocompleteSearchKnowledgeBaseAnswerDocument, options);
}
export type AutocompleteSearchKnowledgeBaseAnswerQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>;