import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatAgentStateAttributesFragmentDoc } from '../fragments/chatAgentStateAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChatAgentStateDocument = gql`
    query chatAgentState {
  chatAgentState {
    ...chatAgentStateAttributes
  }
}
    ${ChatAgentStateAttributesFragmentDoc}
${ChatTopicAttributesFragmentDoc}
${ChatSessionAttributesFragmentDoc}
${ChatAgentAttributesFragmentDoc}`;
export function useChatAgentStateQuery(options: VueApolloComposable.UseQueryOptions<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>(ChatAgentStateDocument, {}, options);
}
export function useChatAgentStateLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>(ChatAgentStateDocument, {}, options);
}
export type ChatAgentStateQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>;