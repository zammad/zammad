import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChatSessionTypingDocument = gql`
    mutation chatSessionTyping($sessionId: ID!) {
  chatSessionTyping(sessionId: $sessionId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChatSessionTypingMutation(options: VueApolloComposable.UseMutationOptions<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables>(ChatSessionTypingDocument, options);
}
export type ChatSessionTypingMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables>;