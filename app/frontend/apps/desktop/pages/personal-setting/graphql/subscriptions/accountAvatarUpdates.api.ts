import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountAvatarUpdatesDocument = gql`
    subscription accountAvatarUpdates($userId: ID!) {
  accountAvatarUpdates(userId: $userId) {
    avatars {
      id
      default
      deletable
      initial
      imageHash
      createdAt
      updatedAt
    }
  }
}
    `;
export function useAccountAvatarUpdatesSubscription(variables: Types.AccountAvatarUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.AccountAvatarUpdatesSubscriptionVariables> | ReactiveFunction<Types.AccountAvatarUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.AccountAvatarUpdatesSubscription, Types.AccountAvatarUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.AccountAvatarUpdatesSubscription, Types.AccountAvatarUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.AccountAvatarUpdatesSubscription, Types.AccountAvatarUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.AccountAvatarUpdatesSubscription, Types.AccountAvatarUpdatesSubscriptionVariables>(AccountAvatarUpdatesDocument, variables, options);
}
export type AccountAvatarUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.AccountAvatarUpdatesSubscription, Types.AccountAvatarUpdatesSubscriptionVariables>;