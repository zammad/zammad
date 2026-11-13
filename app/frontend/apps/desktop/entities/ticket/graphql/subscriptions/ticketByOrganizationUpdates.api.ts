import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketByOrganizationUpdatesDocument = gql`
    subscription ticketByOrganizationUpdates($organizationId: ID!) {
  ticketByOrganizationUpdates(organizationId: $organizationId) {
    listChanged
  }
}
    `;
export function useTicketByOrganizationUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables>(TicketByOrganizationUpdatesDocument, options);
}
export type TicketByOrganizationUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketByOrganizationUpdatesSubscription, Types.TicketByOrganizationUpdatesSubscriptionVariables>;