import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemListUpdatesDocument = gql`
    subscription userCurrentTaskbarItemListUpdates($userId: ID!, $app: EnumTaskbarApp!) {
  userCurrentTaskbarItemListUpdates(userId: $userId, app: $app) {
    taskbarItemList {
      id
      prio
    }
  }
}
    `;
export function useUserCurrentTaskbarItemListUpdatesSubscription(variables: Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>(UserCurrentTaskbarItemListUpdatesDocument, variables, options);
}
export type UserCurrentTaskbarItemListUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentTaskbarItemListUpdatesSubscription, Types.UserCurrentTaskbarItemListUpdatesSubscriptionVariables>;