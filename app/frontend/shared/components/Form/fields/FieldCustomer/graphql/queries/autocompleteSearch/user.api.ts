import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../../../../graphql/fragments/userAttributes.api';
import { UserPersonalSettingsFragmentDoc } from '../../../../../../../graphql/fragments/userPersonalSettings.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../../graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchUserDocument = gql`
    query autocompleteSearchUser($input: AutocompleteSearchUserInput!) {
  autocompleteSearchUser(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
    user {
      ...userAttributes
      vip
      outOfOffice
      outOfOfficeStartAt
      outOfOfficeEndAt
      active
    }
  }
}
    ${UserAttributesFragmentDoc}
${UserPersonalSettingsFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useAutocompleteSearchUserQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>(AutocompleteSearchUserDocument, options);
}
export function useAutocompleteSearchUserLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>(AutocompleteSearchUserDocument, options);
}
export type AutocompleteSearchUserQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>;