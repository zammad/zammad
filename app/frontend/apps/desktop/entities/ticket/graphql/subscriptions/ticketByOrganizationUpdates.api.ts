import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketByOrganizationUpdatesDocument = gql`
    subscription ticketByOrganizationUpdates($organizationId: ID!) {
  ticketByOrganizationUpdates(organizationId: $organizationId) {
    listChanged
  }
}
    `;
export function useTicketByOrganizationUpdatesSubscription(variables: Types.TicketByOrganizationUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketByOrganizationUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketByOrganizationUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables>(TicketByOrganizationUpdatesDocument, variables, options);
}
export type TicketByOrganizationUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables>;