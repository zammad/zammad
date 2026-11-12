import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useChatAgentHeartbeatMutation(options: VueApolloComposable.UseMutationOptions<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables>(ChatAgentHeartbeatDocument, options);
}
export type ChatAgentHeartbeatMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables>;