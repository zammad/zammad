import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useChatSessionTypingMutation(options: VueApolloComposable.useMutation.Options<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables>(ChatSessionTypingDocument, options);
}
export type ChatSessionTypingMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables>;