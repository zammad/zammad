import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketUpdateBulkDocument = gql`
    mutation ticketUpdateBulk($selector: TicketBulkSelectorInput!, $perform: TicketBulkPerformInput!) {
  ticketUpdateBulk(selector: $selector, perform: $perform) {
    async
    total
    failedCount
    inaccessibleTicketIds
    invalidTicketIds
  }
}
    `;
export function useTicketUpdateBulkMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables>(TicketUpdateBulkDocument, options);
}
export type TicketUpdateBulkMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables>;