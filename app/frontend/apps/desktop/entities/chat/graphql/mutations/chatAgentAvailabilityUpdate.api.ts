import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useChatAgentAvailabilityUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables>(ChatAgentAvailabilityUpdateDocument, options);
}
export type ChatAgentAvailabilityUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables>;