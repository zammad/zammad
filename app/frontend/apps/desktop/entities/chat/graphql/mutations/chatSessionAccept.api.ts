import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatSessionAcceptDocument = gql`
    mutation chatSessionAccept($topicId: ID) {
  chatSessionAccept(topicId: $topicId) {
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
export function useChatSessionAcceptMutation(options: VueApolloComposable.useMutation.Options<Types.ChatSessionAcceptMutation, Types.ChatSessionAcceptMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionAcceptMutation, Types.ChatSessionAcceptMutationVariables>(ChatSessionAcceptDocument, options);
}
export type ChatSessionAcceptMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatSessionAcceptMutation, Types.ChatSessionAcceptMutationVariables>;