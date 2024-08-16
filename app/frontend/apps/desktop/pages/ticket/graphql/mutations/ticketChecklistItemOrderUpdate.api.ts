import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketChecklistItemOrderUpdateDocument = gql`
    mutation ticketChecklistItemOrderUpdate($checklistId: ID!, $order: [ID!]!) {
  ticketChecklistItemOrderUpdate(checklistId: $checklistId, order: $order) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketChecklistItemOrderUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemOrderUpdateMutation, Types.TicketChecklistItemOrderUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemOrderUpdateMutation, Types.TicketChecklistItemOrderUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistItemOrderUpdateMutation, Types.TicketChecklistItemOrderUpdateMutationVariables>(TicketChecklistItemOrderUpdateDocument, options);
}
export type TicketChecklistItemOrderUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketChecklistItemOrderUpdateMutation, Types.TicketChecklistItemOrderUpdateMutationVariables>;