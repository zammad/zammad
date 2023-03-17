import * as Types from '../../../../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TextModuleSuggestionsDocument = gql`
    query textModuleSuggestions($query: String!, $limit: Int, $ticketId: ID, $customerId: ID) {
  textModuleSuggestions(query: $query, limit: $limit) {
    id
    name
    keywords
    renderedContent(
      templateRenderContext: {ticketId: $ticketId, customerId: $customerId}
    )
  }
}
    `;
export function useTextModuleSuggestionsQuery(variables: Types.TextModuleSuggestionsQueryVariables | VueCompositionApi.Ref<Types.TextModuleSuggestionsQueryVariables> | ReactiveFunction<Types.TextModuleSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>(TextModuleSuggestionsDocument, variables, options);
}
export function useTextModuleSuggestionsLazyQuery(variables: Types.TextModuleSuggestionsQueryVariables | VueCompositionApi.Ref<Types.TextModuleSuggestionsQueryVariables> | ReactiveFunction<Types.TextModuleSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>(TextModuleSuggestionsDocument, variables, options);
}
export type TextModuleSuggestionsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>;