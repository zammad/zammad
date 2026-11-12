import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CurrentUserAttributesFragmentDoc } from '../fragments/currentUserAttributes.api';
import { UserAttributesFragmentDoc } from '../fragments/userAttributes.api';
import { UserPersonalSettingsFragmentDoc } from '../fragments/userPersonalSettings.api';
import { ObjectAttributeValuesFragmentDoc } from '../fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const CurrentUserUpdatesDocument = gql`
    subscription currentUserUpdates($userId: ID!) {
  userUpdates(userId: $userId) {
    user {
      ...currentUserAttributes
    }
  }
}
    ${CurrentUserAttributesFragmentDoc}
${UserAttributesFragmentDoc}
${UserPersonalSettingsFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useCurrentUserUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables>(CurrentUserUpdatesDocument, options);
}
export type CurrentUserUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables>;