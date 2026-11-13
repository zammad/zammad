import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatPreferencesAttributesFragmentDoc } from '../fragments/chatPreferencesAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatPreferencesDocument = gql`
    query chatPreferences {
  chatPreferences {
    ...chatPreferencesAttributes
  }
}
    ${ChatPreferencesAttributesFragmentDoc}
${ChatTopicAttributesFragmentDoc}`;
export function useChatPreferencesQuery(options: VueApolloComposable.useQuery.Options<Types.ChatPreferencesQuery, Types.ChatPreferencesQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.ChatPreferencesQuery, Types.ChatPreferencesQueryVariables>(ChatPreferencesDocument, options);
}
export function useChatPreferencesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.ChatPreferencesQuery, Types.ChatPreferencesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.ChatPreferencesQuery, Types.ChatPreferencesQueryVariables>(ChatPreferencesDocument, options);
}
export type ChatPreferencesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.ChatPreferencesQuery, Types.ChatPreferencesQueryVariables>;