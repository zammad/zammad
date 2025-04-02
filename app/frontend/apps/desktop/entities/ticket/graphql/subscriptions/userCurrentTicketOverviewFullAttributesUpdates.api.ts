import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserCurrentTicketOverviewFullAttributesUpdatesSubscription(variables: Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>(UserCurrentTicketOverviewFullAttributesUpdatesDocument, variables, options);
}
export type UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription, Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscriptionVariables>;