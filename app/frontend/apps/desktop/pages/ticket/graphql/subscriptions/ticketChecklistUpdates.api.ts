import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
        ticket {
          id
          internalId
          number
          title
          state {
            name
          }
          stateColorCode
        }
        ticketAccess
      }
    }
    removedTicketChecklist
  }
}
    `;
export function useTicketChecklistUpdatesSubscription(variables: Types.TicketChecklistUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketChecklistUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketChecklistUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables>(TicketChecklistUpdatesDocument, variables, options);
}
export type TicketChecklistUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketChecklistUpdatesSubscription, Types.TicketChecklistUpdatesSubscriptionVariables>;