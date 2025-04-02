import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserCurrentTicketOverviewUpdatesSubscription(variables: Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>(UserCurrentTicketOverviewUpdatesDocument, variables, options);
}
export type UserCurrentTicketOverviewUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentTicketOverviewUpdatesSubscription, Types.UserCurrentTicketOverviewUpdatesSubscriptionVariables>;