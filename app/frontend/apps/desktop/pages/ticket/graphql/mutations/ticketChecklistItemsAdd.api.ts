import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketChecklistItemsAddDocument = gql`
    mutation ticketChecklistItemsAdd($checklistId: ID!, $input: [TicketChecklistItemInput!]!) {
  ticketChecklistItemsAdd(checklistId: $checklistId, input: $input) {
    success
  }
}
    `;
export function useTicketChecklistItemsAddMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemsAddMutation, Types.TicketChecklistItemsAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemsAddMutation, Types.TicketChecklistItemsAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistItemsAddMutation, Types.TicketChecklistItemsAddMutationVariables>(TicketChecklistItemsAddDocument, options);
}
export type TicketChecklistItemsAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketChecklistItemsAddMutation, Types.TicketChecklistItemsAddMutationVariables>;