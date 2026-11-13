import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatAgentHeartbeatDocument = gql`
    mutation chatAgentHeartbeat {
  chatAgentHeartbeat {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChatAgentHeartbeatMutation(options: VueApolloComposable.useMutation.Options<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables>(ChatAgentHeartbeatDocument, options);
}
export type ChatAgentHeartbeatMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables>;