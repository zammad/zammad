import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OnlineNotificationsCountDocument = gql`
    subscription onlineNotificationsCount {
  onlineNotificationsCount {
    unseenCount
  }
}
    `;
export function useOnlineNotificationsCountSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>(OnlineNotificationsCountDocument, {}, options);
}
export type OnlineNotificationsCountSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>;