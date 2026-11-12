import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../../../../../../../entities/organization/graphql/fragments/organizationAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../../graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
    ${OrganizationAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useAutocompleteSearchOrganizationQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>(AutocompleteSearchOrganizationDocument, options);
}
export function useAutocompleteSearchOrganizationLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>(AutocompleteSearchOrganizationDocument, options);
}
export type AutocompleteSearchOrganizationQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchOrganizationQuery, Types.AutocompleteSearchOrganizationQueryVariables>;