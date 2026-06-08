import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketByCustomerUpdatesDocument = gql`
    subscription ticketByCustomerUpdates($customerId: ID!) {
  ticketByCustomerUpdates(customerId: $customerId) {
    listChanged
  }
}
    `;
export function useTicketByCustomerUpdatesSubscription(variables: Types.TicketByCustomerUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketByCustomerUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketByCustomerUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables>(TicketByCustomerUpdatesDocument, variables, options);
}
export type TicketByCustomerUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketByCustomerUpdatesSubscription, Types.TicketByCustomerUpdatesSubscriptionVariables>;