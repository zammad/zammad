import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ReferencingTicketFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/referencingTicket.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketChecklistUpdatesDocument = gql`
    subscription ticketChecklistUpdates($ticketId: ID!) {
  ticketChecklistUpdates(ticketId: $ticketId) {
    ticketChecklist {
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
    removedTicketChecklist
  }
}
    ${ReferencingTicketFragmentDoc}`;
export function useTicketChecklistUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables>(TicketChecklistUpdatesDocument, options);
}
export type TicketChecklistUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables>;