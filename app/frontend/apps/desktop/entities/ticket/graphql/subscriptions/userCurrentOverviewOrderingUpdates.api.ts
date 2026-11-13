import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentOverviewOrderingUpdatesDocument = gql`
    subscription userCurrentOverviewOrderingUpdates($ignoreUserConditions: Boolean!) {
  userCurrentOverviewOrderingUpdates(ignoreUserConditions: $ignoreUserConditions) {
    overviews {
      id
      name
      organizationShared
      outOfOffice
    }
  }
}
    `;
export function useUserCurrentOverviewOrderingUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>(UserCurrentOverviewOrderingUpdatesDocument, options);
}
export type UserCurrentOverviewOrderingUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>;