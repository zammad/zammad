import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../../../../../../../shared/entities/organization/graphql/fragments/organizationAttributes.api';
import { OrganizationMembersFragmentDoc } from '../../../../../../../shared/entities/organization/graphql/fragments/organizationMembers.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OrganizationInfoForPopoverDocument = gql`
    query organizationInfoForPopover($organizationId: ID!, $membersCount: Int) {
  organization(organizationId: $organizationId) {
    ...organizationAttributes
    ...organizationMembers
  }
}
    ${OrganizationAttributesFragmentDoc}
${OrganizationMembersFragmentDoc}`;
export function useOrganizationInfoForPopoverQuery(variables: Types.OrganizationInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.OrganizationInfoForPopoverQueryVariables> | ReactiveFunction<Types.OrganizationInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>(OrganizationInfoForPopoverDocument, variables, options);
}
export function useOrganizationInfoForPopoverLazyQuery(variables?: Types.OrganizationInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.OrganizationInfoForPopoverQueryVariables> | ReactiveFunction<Types.OrganizationInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>(OrganizationInfoForPopoverDocument, variables, options);
}
export type OrganizationInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>;