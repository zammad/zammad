import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OnlineNotificationsCountDocument = gql`
    subscription onlineNotificationsCount($userId: ID!) {
  onlineNotificationsCount(userId: $userId) {
    unseenCount
  }
}
    `;
export function useOnlineNotificationsCountSubscription(variables: Types.OnlineNotificationsCountSubscriptionVariables | VueCompositionApi.Ref<Types.OnlineNotificationsCountSubscriptionVariables> | ReactiveFunction<Types.OnlineNotificationsCountSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>(OnlineNotificationsCountDocument, variables, options);
}
export type OnlineNotificationsCountSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.OnlineNotificationsCountSubscription, Types.OnlineNotificationsCountSubscriptionVariables>;