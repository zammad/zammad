import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDetailAttributesFragmentDoc } from '../../../../graphql/fragments/userDetailAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserDocument = gql`
    query user($userId: ID!, $secondaryOrganizationsCount: Int, $after: String, $hasOrganizationCounts: Boolean! = false) {
  user(userId: $userId) {
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
    ${UserDetailAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useUserQuery(options: VueApolloComposable.useQuery.Options<Types.UserQuery, Types.UserQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserQuery, Types.UserQueryVariables>(UserDocument, options);
}
export function useUserLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserQuery, Types.UserQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserQuery, Types.UserQueryVariables>(UserDocument, options);
}
export type UserQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserQuery, Types.UserQueryVariables>;