import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentRecentCloseUpdatesDocument = gql`
    subscription userCurrentRecentCloseUpdates {
  userCurrentRecentCloseUpdates {
    recentCloseUpdated
  }
}
    `;
export function useUserCurrentRecentCloseUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables>(UserCurrentRecentCloseUpdatesDocument, {}, options);
}
export type UserCurrentRecentCloseUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentRecentCloseUpdatesSubscription, Types.UserCurrentRecentCloseUpdatesSubscriptionVariables>;