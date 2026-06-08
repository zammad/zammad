import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const MentionSuggestionsDocument = gql`
    query mentionSuggestions($query: String!, $groupId: ID!) {
  mentionSuggestions(query: $query, groupId: $groupId) {
    id
    internalId
    fullname
    email
    image
    vip
    outOfOffice
    outOfOfficeStartAt
    outOfOfficeEndAt
    active
  }
}
    `;
export function useMentionSuggestionsQuery(variables: Types.MentionSuggestionsQueryVariables | VueCompositionApi.Ref<Types.MentionSuggestionsQueryVariables> | ReactiveFunction<Types.MentionSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>(MentionSuggestionsDocument, variables, options);
}
export function useMentionSuggestionsLazyQuery(variables?: Types.MentionSuggestionsQueryVariables | VueCompositionApi.Ref<Types.MentionSuggestionsQueryVariables> | ReactiveFunction<Types.MentionSuggestionsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>(MentionSuggestionsDocument, variables, options);
}
export type MentionSuggestionsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>;