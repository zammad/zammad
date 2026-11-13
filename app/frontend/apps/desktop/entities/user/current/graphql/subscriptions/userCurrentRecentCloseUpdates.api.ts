import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentRecentCloseUpdatesDocument = gql`
    subscription userCurrentRecentCloseUpdates {
  userCurrentRecentCloseUpdates {
    recentCloseUpdated
  }
}
    `;
export function useUserCurrentRecentCloseUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables>(UserCurrentRecentCloseUpdatesDocument, options);
}
export type UserCurrentRecentCloseUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables>;