import * as Types from '../../../../../../../graphql/types';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../../../../../../../../apps/mobile/entities/organization/graphql/fragments/organizationAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchOrganizationDocument = gql`
    query autocompleteSearchOrganization($input: AutocompleteSearchOrganizationInput!) {
  autocompleteSearchOrganization(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
    organization {
      ...organizationAttributes
    }
  }
}
    ${OrganizationAttributesFragmentDoc}`;
export function useAutocompleteSearchOrganizationQuery(variables: Types.AutocompleteSearchOrganizationQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchOrganizationQueryVariables> | ReactiveFunction<Types.AutocompleteSearchOrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>(AutocompleteSearchOrganizationDocument, variables, options);
}
export function useAutocompleteSearchOrganizationLazyQuery(variables: Types.AutocompleteSearchOrganizationQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchOrganizationQueryVariables> | ReactiveFunction<Types.AutocompleteSearchOrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>(AutocompleteSearchOrganizationDocument, variables, options);
}
export type AutocompleteSearchOrganizationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>;