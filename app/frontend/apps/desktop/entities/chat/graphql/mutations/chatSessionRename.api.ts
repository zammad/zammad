import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatSessionAttributesFragmentDoc } from '../fragments/chatSessionAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ChatAgentAttributesFragmentDoc } from '../fragments/chatAgentAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useChatSessionRenameMutation(options: VueApolloComposable.UseMutationOptions<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables>(ChatSessionRenameDocument, options);
}
export type ChatSessionRenameMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables>;