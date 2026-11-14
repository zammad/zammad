import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OnlineNotificationsCountDocument = gql`
    subscription onlineNotificationsCount($withPushTags: Boolean! = false) {
  onlineNotificationsCount {
    unseenCount
    unseenPushTags @include(if: $withPushTags)
  }
}
    `;
export function useOnlineNotificationsCountSubscription(options: VueApolloComposable.useSubscription.Options<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>(OnlineNotificationsCountDocument, options);
}
export type OnlineNotificationsCountSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>;