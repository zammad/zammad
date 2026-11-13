import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatSessionTransferDocument = gql`
    mutation chatSessionTransfer($sessionId: ID!, $topicId: ID!) {
  chatSessionTransfer(sessionId: $sessionId, topicId: $topicId) {
    session {
      ...chatSessionAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${ChatSessionAttributesFragmentDoc}
${ChatTopicAttributesFragmentDoc}
${ChatAgentAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useChatSessionTransferMutation(options: VueApolloComposable.useMutation.Options<Types.ChatSessionTransferMutation, Types.ChatSessionTransferMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionTransferMutation, Types.ChatSessionTransferMutationVariables>(ChatSessionTransferDocument, options);
}
export type ChatSessionTransferMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatSessionTransferMutation, Types.ChatSessionTransferMutationVariables>;