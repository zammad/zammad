import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useMentionSuggestionsQuery(options: VueApolloComposable.useQuery.Options<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>(MentionSuggestionsDocument, options);
}
export function useMentionSuggestionsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>(MentionSuggestionsDocument, options);
}
export type MentionSuggestionsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>;