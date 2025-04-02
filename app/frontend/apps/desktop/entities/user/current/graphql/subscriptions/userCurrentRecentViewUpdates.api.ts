import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentRecentViewUpdatesDocument = gql`
    subscription userCurrentRecentViewUpdates {
  userCurrentRecentViewUpdates {
    recentViewsUpdated
  }
}
    `;
export function useUserCurrentRecentViewUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentRecentViewUpdatesSubscription, Types.UserCurrentRecentViewUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentRecentViewUpdatesSubscription, Types.UserCurrentRecentViewUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentRecentViewUpdatesSubscription, Types.UserCurrentRecentViewUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentRecentViewUpdatesSubscription, Types.UserCurrentRecentViewUpdatesSubscriptionVariables>(UserCurrentRecentViewUpdatesDocument, {}, options);
}
export type UserCurrentRecentViewUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentRecentViewUpdatesSubscription, Types.UserCurrentRecentViewUpdatesSubscriptionVariables>;