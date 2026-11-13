import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTwoFactorUpdatesDocument = gql`
    subscription userCurrentTwoFactorUpdates {
  userCurrentTwoFactorUpdates {
    configuration {
      recoveryCodesExist
      enabledAuthenticationMethods {
        configured
        authenticationMethod
      }
    }
  }
}
    `;
export function useUserCurrentTwoFactorUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentTwoFactorUpdatesSubscription, Types.UserCurrentTwoFactorUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTwoFactorUpdatesSubscription, Types.UserCurrentTwoFactorUpdatesSubscriptionVariables>(UserCurrentTwoFactorUpdatesDocument, options);
}
export type UserCurrentTwoFactorUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentTwoFactorUpdatesSubscription, Types.UserCurrentTwoFactorUpdatesSubscriptionVariables>;