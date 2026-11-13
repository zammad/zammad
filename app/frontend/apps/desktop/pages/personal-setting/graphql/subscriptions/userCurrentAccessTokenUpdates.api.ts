import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TokenAttributesFragmentDoc } from '../../../../../../shared/entities/user/current/graphql/fragments/tokenAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentAccessTokenUpdatesDocument = gql`
    subscription userCurrentAccessTokenUpdates {
  userCurrentAccessTokenUpdates {
    tokens {
      ...tokenAttributes
    }
  }
}
    ${TokenAttributesFragmentDoc}`;
export function useUserCurrentAccessTokenUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentAccessTokenUpdatesSubscription, Types.UserCurrentAccessTokenUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentAccessTokenUpdatesSubscription, Types.UserCurrentAccessTokenUpdatesSubscriptionVariables>(UserCurrentAccessTokenUpdatesDocument, options);
}
export type UserCurrentAccessTokenUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentAccessTokenUpdatesSubscription, Types.UserCurrentAccessTokenUpdatesSubscriptionVariables>;