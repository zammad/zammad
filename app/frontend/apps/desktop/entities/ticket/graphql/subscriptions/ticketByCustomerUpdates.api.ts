import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketByCustomerUpdatesDocument = gql`
    subscription ticketByCustomerUpdates($customerId: ID!) {
  ticketByCustomerUpdates(customerId: $customerId) {
    listChanged
  }
}
    `;
export function useTicketByCustomerUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables>(TicketByCustomerUpdatesDocument, options);
}
export type TicketByCustomerUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables>;