import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../fragments/organizationAttributes.api';
import { OrganizationMembersWithFetchMoreFragmentDoc } from '../fragments/organizationMembersWithFetchMore.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
${OrganizationMembersWithFetchMoreFragmentDoc}`;
export function useOrganizationQuery(variables: Types.OrganizationQueryVariables | VueCompositionApi.Ref<Types.OrganizationQueryVariables> | ReactiveFunction<Types.OrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OrganizationQuery, Types.OrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OrganizationQuery, Types.OrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OrganizationQuery, Types.OrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OrganizationQuery, Types.OrganizationQueryVariables>(OrganizationDocument, variables, options);
}
export function useOrganizationLazyQuery(variables?: Types.OrganizationQueryVariables | VueCompositionApi.Ref<Types.OrganizationQueryVariables> | ReactiveFunction<Types.OrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OrganizationQuery, Types.OrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OrganizationQuery, Types.OrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OrganizationQuery, Types.OrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.OrganizationQuery, Types.OrganizationQueryVariables>(OrganizationDocument, variables, options);
}
export type OrganizationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OrganizationQuery, Types.OrganizationQueryVariables>;