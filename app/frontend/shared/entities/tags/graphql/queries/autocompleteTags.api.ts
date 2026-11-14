import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchTagDocument = gql`
    query autocompleteSearchTag($input: AutocompleteSearchTagInput!) {
  autocompleteSearchTag(input: $input) {
    value
    label
  }
}
    `;
export function useAutocompleteSearchTagQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>(AutocompleteSearchTagDocument, options);
}
export function useAutocompleteSearchTagLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>(AutocompleteSearchTagDocument, options);
}
export type AutocompleteSearchTagQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>;