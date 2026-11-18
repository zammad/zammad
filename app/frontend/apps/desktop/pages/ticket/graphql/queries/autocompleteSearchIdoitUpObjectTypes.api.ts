import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchIdoitUpObjectTypesDocument = gql`
    query autocompleteSearchIdoitUpObjectTypes($input: AutocompleteSearchInput!) {
  autocompleteSearchIdoitUpObjectTypes(input: $input) {
    value
    label
  }
}
    `;
export function useAutocompleteSearchIdoitUpObjectTypesQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchIdoitUpObjectTypesQuery, Types.AutocompleteSearchIdoitUpObjectTypesQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchIdoitUpObjectTypesQuery, Types.AutocompleteSearchIdoitUpObjectTypesQueryVariables>(AutocompleteSearchIdoitUpObjectTypesDocument, options);
}
export function useAutocompleteSearchIdoitUpObjectTypesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchIdoitUpObjectTypesQuery, Types.AutocompleteSearchIdoitUpObjectTypesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchIdoitUpObjectTypesQuery, Types.AutocompleteSearchIdoitUpObjectTypesQueryVariables>(AutocompleteSearchIdoitUpObjectTypesDocument, options);
}
export type AutocompleteSearchIdoitUpObjectTypesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchIdoitUpObjectTypesQuery, Types.AutocompleteSearchIdoitUpObjectTypesQueryVariables>;