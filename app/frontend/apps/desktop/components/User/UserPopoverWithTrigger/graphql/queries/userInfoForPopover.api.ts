import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDetailAttributesFragmentDoc } from '../../../../../../../shared/graphql/fragments/userDetailAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserInfoForPopoverDocument = gql`
    query userInfoForPopover($userId: ID!, $secondaryOrganizationsCount: Int, $after: String) {
  user(userId: $userId) {
    ...userDetailAttributes
  }
}
    ${UserDetailAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useUserInfoForPopoverQuery(options: VueApolloComposable.useQuery.Options<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>(UserInfoForPopoverDocument, options);
}
export function useUserInfoForPopoverLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>(UserInfoForPopoverDocument, options);
}
export type UserInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>;