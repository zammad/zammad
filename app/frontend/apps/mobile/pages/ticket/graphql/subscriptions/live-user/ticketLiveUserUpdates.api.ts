import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { TicketLiveUserAttributesFragmentDoc } from '../../fragments/live-user/ticketLiveUserAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketLiveUserUpdatesDocument = gql`
    subscription ticketLiveUserUpdates($userId: ID!, $key: String!, $app: EnumTaskbarApp!) {
  ticketLiveUserUpdates(userId: $userId, key: $key, app: $app) {
    liveUsers {
      ...ticketLiveUserAttributes
    }
  }
}
    ${TicketLiveUserAttributesFragmentDoc}`;
export function useTicketLiveUserUpdatesSubscription(variables: Types.TicketLiveUserUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketLiveUserUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketLiveUserUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables>(TicketLiveUserUpdatesDocument, variables, options);
}
export type TicketLiveUserUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketLiveUserUpdatesSubscription, Types.TicketLiveUserUpdatesSubscriptionVariables>;