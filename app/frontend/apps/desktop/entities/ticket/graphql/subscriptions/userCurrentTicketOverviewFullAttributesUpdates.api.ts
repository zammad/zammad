import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTicketOverviewFullAttributesUpdatesDocument = gql`
    subscription userCurrentTicketOverviewFullAttributesUpdates($ignoreUserConditions: Boolean!, $withTicketCount: Boolean = false) {
  userCurrentTicketOverviewUpdates(ignoreUserConditions: $ignoreUserConditions) {
    ticketOverviews {
      ...overviewAttributes
      viewColumnsRaw
    }
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useUserCurrentTicketOverviewFullAttributesUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>(UserCurrentTicketOverviewFullAttributesUpdatesDocument, options);
}
export type UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>;