import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentAvatarUpdatesDocument = gql`
    subscription userCurrentAvatarUpdates {
  userCurrentAvatarUpdates {
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
export function useUserCurrentAvatarUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables>(UserCurrentAvatarUpdatesDocument, {}, options);
}
export type UserCurrentAvatarUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables>;