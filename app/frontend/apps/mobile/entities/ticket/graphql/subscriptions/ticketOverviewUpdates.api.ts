import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketOverviewUpdatesDocument = gql`
    subscription ticketOverviewUpdates($ignoreUserConditions: Boolean = false, $withTicketCount: Boolean!) {
  ticketOverviewUpdates(ignoreUserConditions: $ignoreUserConditions) {
    ticketOverviews {
      ...overviewAttributes
      viewColumns {
        key
        value
      }
      orderColumns {
        key
        value
      }
    }
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useTicketOverviewUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables>(TicketOverviewUpdatesDocument, options);
}
export type TicketOverviewUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables>;