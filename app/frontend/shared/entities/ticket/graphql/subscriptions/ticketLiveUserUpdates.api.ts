import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketLiveUserAttributesFragmentDoc } from '../fragments/ticketLiveUserAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketLiveUserUpdatesDocument = gql`
    subscription ticketLiveUserUpdates($key: String!, $app: EnumTaskbarApp!) {
  ticketLiveUserUpdates(key: $key, app: $app) {
    liveUsers {
      ...ticketLiveUserAttributes
    }
  }
}
    ${TicketLiveUserAttributesFragmentDoc}`;
export function useTicketLiveUserUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables>(TicketLiveUserUpdatesDocument, options);
}
export type TicketLiveUserUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables>;