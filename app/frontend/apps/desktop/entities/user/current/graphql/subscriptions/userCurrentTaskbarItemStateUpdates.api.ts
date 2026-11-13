import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemStateUpdatesDocument = gql`
    subscription userCurrentTaskbarItemStateUpdates($taskbarItemId: ID!) {
  userCurrentTaskbarItemStateUpdates(taskbarItemId: $taskbarItemId) {
    stateUpdateType
  }
}
    `;
export function useUserCurrentTaskbarItemStateUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>(UserCurrentTaskbarItemStateUpdatesDocument, options);
}
export type UserCurrentTaskbarItemStateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>;