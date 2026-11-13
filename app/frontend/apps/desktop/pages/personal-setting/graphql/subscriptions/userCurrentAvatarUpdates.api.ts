import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentAvatarUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables>(UserCurrentAvatarUpdatesDocument, options);
}
export type UserCurrentAvatarUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentAvatarUpdatesSubscription, Types.UserCurrentAvatarUpdatesSubscriptionVariables>;