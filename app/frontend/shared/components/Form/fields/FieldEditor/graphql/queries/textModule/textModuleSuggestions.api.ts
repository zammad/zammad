import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TextModuleSuggestionsDocument = gql`
    query textModuleSuggestions($query: String!, $limit: Int, $ticketId: ID, $customerId: ID, $groupId: ID) {
  textModuleSuggestions(
    query: $query
    groupId: $groupId
    ticketId: $ticketId
    limit: $limit
  ) {
    id
    name
    keywords
    renderedContent(
      templateRenderContext: { ticketId: $ticketId, customerId: $customerId }
    )
  }
}
    `;
export function useTextModuleSuggestionsQuery(options: VueApolloComposable.useQuery.Options<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>(TextModuleSuggestionsDocument, options);
}
export function useTextModuleSuggestionsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>(TextModuleSuggestionsDocument, options);
}
export type TextModuleSuggestionsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>;