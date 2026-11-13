import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemListUpdatesDocument = gql`
    subscription userCurrentTaskbarItemListUpdates($app: EnumTaskbarApp!) {
  userCurrentTaskbarItemListUpdates(app: $app) {
    taskbarItemList {
      id
      prio
    }
  }
}
    `;
export function useUserCurrentTaskbarItemListUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>(UserCurrentTaskbarItemListUpdatesDocument, options);
}
export type UserCurrentTaskbarItemListUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>;