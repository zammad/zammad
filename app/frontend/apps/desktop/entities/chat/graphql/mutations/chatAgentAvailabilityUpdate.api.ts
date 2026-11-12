import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChatAgentAvailabilityUpdateDocument = gql`
    mutation chatAgentAvailabilityUpdate($active: Boolean!) {
  chatAgentAvailabilityUpdate(active: $active) {
    active
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChatAgentAvailabilityUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables>(ChatAgentAvailabilityUpdateDocument, options);
}
export type ChatAgentAvailabilityUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables>;