import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentOverviewOrderingFullAttributesUpdatesDocument = gql`
    subscription userCurrentOverviewOrderingFullAttributesUpdates($ignoreUserConditions: Boolean!, $withTicketCount: Boolean = false) {
  userCurrentOverviewOrderingUpdates(ignoreUserConditions: $ignoreUserConditions) {
    overviews {
      ...overviewAttributes
      viewColumnsRaw
    }
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useUserCurrentOverviewOrderingFullAttributesUpdatesSubscription(variables: Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>(UserCurrentOverviewOrderingFullAttributesUpdatesDocument, variables, options);
}
export type UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>;