import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchRecipientDocument = gql`
    query autocompleteSearchRecipient($input: AutocompleteSearchRecipientInput!) {
  autocompleteSearchRecipient(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
  }
}
    `;
export function useAutocompleteSearchRecipientQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>(AutocompleteSearchRecipientDocument, options);
}
export function useAutocompleteSearchRecipientLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>(AutocompleteSearchRecipientDocument, options);
}
export type AutocompleteSearchRecipientQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>;