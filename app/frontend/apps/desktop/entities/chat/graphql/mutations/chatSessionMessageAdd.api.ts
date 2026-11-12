import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatMessageAttributesFragmentDoc } from '../fragments/chatMessageAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChatSessionMessageAddDocument = gql`
    mutation chatSessionMessageAdd($sessionId: ID!, $content: String!) {
  chatSessionMessageAdd(sessionId: $sessionId, content: $content) {
    message {
      ...chatMessageAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${ChatMessageAttributesFragmentDoc}
${ChatAgentAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useChatSessionMessageAddMutation(options: VueApolloComposable.UseMutationOptions<Types.ChatSessionMessageAddMutation, Types.ChatSessionMessageAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChatSessionMessageAddMutation, Types.ChatSessionMessageAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionMessageAddMutation, Types.ChatSessionMessageAddMutationVariables>(ChatSessionMessageAddDocument, options);
}
export type ChatSessionMessageAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChatSessionMessageAddMutation, Types.ChatSessionMessageAddMutationVariables>;