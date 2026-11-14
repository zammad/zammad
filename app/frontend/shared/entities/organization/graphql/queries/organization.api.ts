import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../fragments/organizationAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { OrganizationMembersWithFetchMoreFragmentDoc } from '../fragments/organizationMembersWithFetchMore.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OrganizationDocument = gql`
    query organization($organizationId: ID!, $first: Int, $after: String) {
  organization(organizationId: $organizationId) {
    ...organizationAttributes
    ...organizationMembersWithFetchMore
    policy {
      update
    }
    ticketsCount {
      open
      closed
      openSearchQuery
      closedSearchQuery
    }
  }
}
    ${OrganizationAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}
${OrganizationMembersWithFetchMoreFragmentDoc}`;
export function useOrganizationQuery(options: VueApolloComposable.useQuery.Options<Types.OrganizationQuery, Types.OrganizationQueryVariables>) {
  return VueApolloComposable.useQuery<Types.OrganizationQuery, Types.OrganizationQueryVariables>(OrganizationDocument, options);
}
export function useOrganizationLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.OrganizationQuery, Types.OrganizationQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.OrganizationQuery, Types.OrganizationQueryVariables>(OrganizationDocument, options);
}
export type OrganizationQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.OrganizationQuery, Types.OrganizationQueryVariables>;