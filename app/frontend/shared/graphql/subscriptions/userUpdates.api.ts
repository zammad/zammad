import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDetailAttributesFragmentDoc } from '../fragments/userDetailAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserUpdatesDocument = gql`
    subscription userUpdates($userId: ID!, $secondaryOrganizationsCount: Int, $after: String, $hasOrganizationCounts: Boolean! = false, $initial: Boolean = false) {
  userUpdates(userId: $userId, initial: $initial) {
    user {
      ...userDetailAttributes
      hasSecondaryOrganizations
      ticketsCount {
        open
        openSearchQuery
        closed
        closedSearchQuery
        organizationOpen @include(if: $hasOrganizationCounts)
        organizationOpenSearchQuery @include(if: $hasOrganizationCounts)
        organizationClosed @include(if: $hasOrganizationCounts)
        organizationClosedSearchQuery @include(if: $hasOrganizationCounts)
      }
      policy {
        update
      }
    }
  }
}
    ${UserDetailAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useUserUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserUpdatesSubscription, Types.UserUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserUpdatesSubscription, Types.UserUpdatesSubscriptionVariables>(UserUpdatesDocument, options);
}
export type UserUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserUpdatesSubscription, Types.UserUpdatesSubscriptionVariables>;