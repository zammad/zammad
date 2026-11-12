import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ChatMessageAttributesFragmentDoc } from '../fragments/chatMessageAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useChatSessionQuery(variables: Types.ChatSessionQueryVariables | VueCompositionApi.Ref<Types.ChatSessionQueryVariables> | ReactiveFunction<Types.ChatSessionQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.ChatSessionQuery, Types.ChatSessionQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>(ChatSessionDocument, variables, options);
}
export function useChatSessionLazyQuery(variables?: Types.ChatSessionQueryVariables | VueCompositionApi.Ref<Types.ChatSessionQueryVariables> | ReactiveFunction<Types.ChatSessionQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.ChatSessionQuery, Types.ChatSessionQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>(ChatSessionDocument, variables, options);
}
export type ChatSessionQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>;