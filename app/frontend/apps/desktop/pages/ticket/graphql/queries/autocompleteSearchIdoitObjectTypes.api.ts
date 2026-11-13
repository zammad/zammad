import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchIdoitObjectTypesDocument = gql`
    query autocompleteSearchIdoitObjectTypes($input: AutocompleteSearchInput!) {
  autocompleteSearchIdoitObjectTypes(input: $input) {
    value
    label
  }
}
    `;
export function useAutocompleteSearchIdoitObjectTypesQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>(AutocompleteSearchIdoitObjectTypesDocument, options);
}
export function useAutocompleteSearchIdoitObjectTypesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>(AutocompleteSearchIdoitObjectTypesDocument, options);
}
export type AutocompleteSearchIdoitObjectTypesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>;