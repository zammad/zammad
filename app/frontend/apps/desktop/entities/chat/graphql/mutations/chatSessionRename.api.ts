import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatSessionRenameDocument = gql`
    mutation chatSessionRename($sessionId: ID!, $name: String!) {
  chatSessionRename(sessionId: $sessionId, name: $name) {
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
export function useChatSessionRenameMutation(options: VueApolloComposable.useMutation.Options<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables>(ChatSessionRenameDocument, options);
}
export type ChatSessionRenameMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables>;