import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatAgentStateAttributesFragmentDoc } from '../fragments/chatAgentStateAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChatAgentStateUpdatesDocument = gql`
    subscription chatAgentStateUpdates {
  chatAgentStateUpdates {
    agentState {
      ...chatAgentStateAttributes
    }
  }
}
    ${ChatAgentStateAttributesFragmentDoc}
${ChatTopicAttributesFragmentDoc}
${ChatSessionAttributesFragmentDoc}
${ChatAgentAttributesFragmentDoc}`;
export function useChatAgentStateUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.ChatAgentStateUpdatesSubscription, Types.ChatAgentStateUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.ChatAgentStateUpdatesSubscription, Types.ChatAgentStateUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.ChatAgentStateUpdatesSubscription, Types.ChatAgentStateUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.ChatAgentStateUpdatesSubscription, Types.ChatAgentStateUpdatesSubscriptionVariables>(ChatAgentStateUpdatesDocument, {}, options);
}
export type ChatAgentStateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.ChatAgentStateUpdatesSubscription, Types.ChatAgentStateUpdatesSubscriptionVariables>;