import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentOverviewOrderingFullAttributesUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>(UserCurrentOverviewOrderingFullAttributesUpdatesDocument, options);
}
export type UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscription, Types.UserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionVariables>;