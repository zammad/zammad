import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatMessageAttributesFragmentDoc } from '../fragments/chatMessageAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatSessionUpdatesDocument = gql`
    subscription chatSessionUpdates($sessionId: ID!) {
  chatSessionUpdates(sessionId: $sessionId) {
    message {
      ...chatMessageAttributes
    }
    typing
    notice
    leftBy
    closedBy
  }
}
    ${ChatMessageAttributesFragmentDoc}
${ChatAgentAttributesFragmentDoc}`;
export function useChatSessionUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables>(ChatSessionUpdatesDocument, options);
}
export type ChatSessionUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables>;