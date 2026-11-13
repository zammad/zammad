import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTicketOverviewUpdatesDocument = gql`
    subscription userCurrentTicketOverviewUpdates($ignoreUserConditions: Boolean!) {
  userCurrentTicketOverviewUpdates(ignoreUserConditions: $ignoreUserConditions) {
    ticketOverviews {
      id
      name
    }
  }
}
    `;
export function useUserCurrentTicketOverviewUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>(UserCurrentTicketOverviewUpdatesDocument, options);
}
export type UserCurrentTicketOverviewUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>;