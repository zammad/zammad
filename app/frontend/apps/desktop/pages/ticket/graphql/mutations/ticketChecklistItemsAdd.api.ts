import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketChecklistItemsAddDocument = gql`
    mutation ticketChecklistItemsAdd($checklistId: ID!, $input: [TicketChecklistItemInput!]!) {
  ticketChecklistItemsAdd(checklistId: $checklistId, input: $input) {
    success
  }
}
    `;
export function useTicketChecklistItemsAddMutation(options: VueApolloComposable.useMutation.Options<Types.TicketChecklistItemsAddMutation, Types.TicketChecklistItemsAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistItemsAddMutation, Types.TicketChecklistItemsAddMutationVariables>(TicketChecklistItemsAddDocument, options);
}
export type TicketChecklistItemsAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketChecklistItemsAddMutation, Types.TicketChecklistItemsAddMutationVariables>;