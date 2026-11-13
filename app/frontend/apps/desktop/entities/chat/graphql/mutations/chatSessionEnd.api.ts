import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatSessionEndDocument = gql`
    mutation chatSessionEnd($sessionId: ID!) {
  chatSessionEnd(sessionId: $sessionId) {
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
export function useChatSessionEndMutation(options: VueApolloComposable.useMutation.Options<Types.ChatSessionEndMutation, Types.ChatSessionEndMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionEndMutation, Types.ChatSessionEndMutationVariables>(ChatSessionEndDocument, options);
}
export type ChatSessionEndMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatSessionEndMutation, Types.ChatSessionEndMutationVariables>;