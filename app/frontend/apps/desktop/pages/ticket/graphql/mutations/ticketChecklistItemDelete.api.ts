import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketChecklistItemDeleteDocument = gql`
    mutation ticketChecklistItemDelete($checklistId: ID!, $checklistItemId: ID!) {
  ticketChecklistItemDelete(
    checklistId: $checklistId
    checklistItemId: $checklistItemId
  ) {
    success
  }
}
    `;
export function useTicketChecklistItemDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables>(TicketChecklistItemDeleteDocument, options);
}
export type TicketChecklistItemDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables>;