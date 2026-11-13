import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchKnowledgeBaseCategoryIconDocument = gql`
    query autocompleteSearchKnowledgeBaseCategoryIcon($input: AutocompleteSearchKnowledgeBaseCategoryIconInput!) {
  autocompleteSearchKnowledgeBaseCategoryIcon(input: $input) {
    value
    label
    iconSet
  }
}
    `;
export function useAutocompleteSearchKnowledgeBaseCategoryIconQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>(AutocompleteSearchKnowledgeBaseCategoryIconDocument, options);
}
export function useAutocompleteSearchKnowledgeBaseCategoryIconLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>(AutocompleteSearchKnowledgeBaseCategoryIconDocument, options);
}
export type AutocompleteSearchKnowledgeBaseCategoryIconQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>;