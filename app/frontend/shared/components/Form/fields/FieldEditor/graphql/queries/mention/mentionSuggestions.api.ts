import * as Types from '../../../../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const MentionSuggestionsDocument = gql`
    query mentionSuggestions($query: String!, $group: ID!) {
  mentionSuggestions(query: $query, group: $group) {
    id
    internalId
    fullname
    email
  }
}
    `;
export function useMentionSuggestionsQuery(variables: Types.MentionSuggestionsQueryVariables | VueCompositionApi.Ref<Types.MentionSuggestionsQueryVariables> | ReactiveFunction<Types.MentionSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>(MentionSuggestionsDocument, variables, options);
}
export function useMentionSuggestionsLazyQuery(variables: Types.MentionSuggestionsQueryVariables | VueCompositionApi.Ref<Types.MentionSuggestionsQueryVariables> | ReactiveFunction<Types.MentionSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>(MentionSuggestionsDocument, variables, options);
}
export type MentionSuggestionsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>;