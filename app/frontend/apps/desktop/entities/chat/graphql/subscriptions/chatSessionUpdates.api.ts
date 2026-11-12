import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatMessageAttributesFragmentDoc } from '../fragments/chatMessageAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useChatSessionUpdatesSubscription(variables: Types.ChatSessionUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.ChatSessionUpdatesSubscriptionVariables> | ReactiveFunction<Types.ChatSessionUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables>(ChatSessionUpdatesDocument, variables, options);
}
export type ChatSessionUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.ChatSessionUpdatesSubscription, Types.ChatSessionUpdatesSubscriptionVariables>;