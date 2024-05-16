import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentOverviewOrderingUpdatesDocument = gql`
    subscription userCurrentOverviewOrderingUpdates($userId: ID!) {
  userCurrentOverviewOrderingUpdates(userId: $userId) {
    overviews {
      id
      name
    }
  }
}
    `;
export function useUserCurrentOverviewOrderingUpdatesSubscription(variables: Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>(UserCurrentOverviewOrderingUpdatesDocument, variables, options);
}
export type UserCurrentOverviewOrderingUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentOverviewOrderingUpdatesSubscription, Types.UserCurrentOverviewOrderingUpdatesSubscriptionVariables>;