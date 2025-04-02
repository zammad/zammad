import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketOverviewUpdatesSubscription(variables: Types.TicketOverviewUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketOverviewUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketOverviewUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables>(TicketOverviewUpdatesDocument, variables, options);
}
export type TicketOverviewUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketOverviewUpdatesSubscription, Types.TicketOverviewUpdatesSubscriptionVariables>;