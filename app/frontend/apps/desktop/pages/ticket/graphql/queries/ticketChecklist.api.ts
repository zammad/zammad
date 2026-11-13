import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ReferencingTicketFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/referencingTicket.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketChecklistDocument = gql`
    query ticketChecklist($ticketId: ID!) {
  ticketChecklist(ticketId: $ticketId) {
    id
    name
    completed
    incomplete
    items {
      id
      text
      checked
      ticketReference {
        ticket {
          ...referencingTicket
        }
      }
    }
  }
}
    ${ReferencingTicketFragmentDoc}`;
export function useTicketChecklistQuery(options: VueApolloComposable.useQuery.Options<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>(TicketChecklistDocument, options);
}
export function useTicketChecklistLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>(TicketChecklistDocument, options);
}
export type TicketChecklistQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>;