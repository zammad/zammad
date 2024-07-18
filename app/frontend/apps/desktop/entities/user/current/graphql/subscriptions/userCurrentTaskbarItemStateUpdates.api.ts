import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemStateUpdatesDocument = gql`
    subscription userCurrentTaskbarItemStateUpdates($taskbarItemId: ID!) {
  userCurrentTaskbarItemStateUpdates(taskbarItemId: $taskbarItemId) {
    stateChanged
  }
}
    `;
export function useUserCurrentTaskbarItemStateUpdatesSubscription(variables: Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>(UserCurrentTaskbarItemStateUpdatesDocument, variables, options);
}
export type UserCurrentTaskbarItemStateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentTaskbarItemStateUpdatesSubscription, Types.UserCurrentTaskbarItemStateUpdatesSubscriptionVariables>;