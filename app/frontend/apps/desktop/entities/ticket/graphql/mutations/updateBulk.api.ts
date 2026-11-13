import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketUpdateBulkMutation(options: VueApolloComposable.useMutation.Options<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables>(TicketUpdateBulkDocument, options);
}
export type TicketUpdateBulkMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables>;