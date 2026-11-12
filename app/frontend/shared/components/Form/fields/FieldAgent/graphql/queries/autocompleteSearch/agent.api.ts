import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../../../../graphql/fragments/userAttributes.api';
import { UserPersonalSettingsFragmentDoc } from '../../../../../../../graphql/fragments/userPersonalSettings.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../../graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchAgentDocument = gql`
    query autocompleteSearchAgent($input: AutocompleteSearchUserInput!) {
  autocompleteSearchAgent(input: $input) {
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
export function useAutocompleteSearchAgentQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>(AutocompleteSearchAgentDocument, options);
}
export function useAutocompleteSearchAgentLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>(AutocompleteSearchAgentDocument, options);
}
export type AutocompleteSearchAgentQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>;