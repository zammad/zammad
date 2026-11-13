import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../../../../../../../shared/entities/organization/graphql/fragments/organizationAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import { OrganizationMembersFragmentDoc } from '../../../../../../../shared/entities/organization/graphql/fragments/organizationMembers.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OrganizationInfoForPopoverDocument = gql`
    query organizationInfoForPopover($organizationId: ID!, $membersCount: Int) {
  organization(organizationId: $organizationId) {
    ...organizationAttributes
    ...organizationMembers
  }
}
    ${OrganizationAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}
${OrganizationMembersFragmentDoc}`;
export function useOrganizationInfoForPopoverQuery(options: VueApolloComposable.useQuery.Options<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useQuery<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>(OrganizationInfoForPopoverDocument, options);
}
export function useOrganizationInfoForPopoverLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>(OrganizationInfoForPopoverDocument, options);
}
export type OrganizationInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>;