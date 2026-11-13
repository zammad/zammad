import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ChatMessageAttributesFragmentDoc } from '../fragments/chatMessageAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatSessionDocument = gql`
    query chatSession($sessionId: ID!) {
  chatSession(sessionId: $sessionId) {
    ...chatSessionAttributes
    tags
    messages {
      ...chatMessageAttributes
    }
  }
}
    ${ChatSessionAttributesFragmentDoc}
${ChatTopicAttributesFragmentDoc}
${ChatAgentAttributesFragmentDoc}
${ChatMessageAttributesFragmentDoc}`;
export function useChatSessionQuery(options: VueApolloComposable.useQuery.Options<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>) {
  return VueApolloComposable.useQuery<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>(ChatSessionDocument, options);
}
export function useChatSessionLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>(ChatSessionDocument, options);
}
export type ChatSessionQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>;