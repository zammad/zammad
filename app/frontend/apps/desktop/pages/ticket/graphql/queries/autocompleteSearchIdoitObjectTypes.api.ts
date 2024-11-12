import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchIdoitObjectTypesDocument = gql`
    query autocompleteSearchIdoitObjectTypes($input: AutocompleteSearchInput!) {
  autocompleteSearchIdoitObjectTypes(input: $input) {
    value
    label
  }
}
    `;
export function useAutocompleteSearchIdoitObjectTypesQuery(variables: Types.AutocompleteSearchIdoitObjectTypesQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchIdoitObjectTypesQueryVariables> | ReactiveFunction<Types.AutocompleteSearchIdoitObjectTypesQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>(AutocompleteSearchIdoitObjectTypesDocument, variables, options);
}
export function useAutocompleteSearchIdoitObjectTypesLazyQuery(variables?: Types.AutocompleteSearchIdoitObjectTypesQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchIdoitObjectTypesQueryVariables> | ReactiveFunction<Types.AutocompleteSearchIdoitObjectTypesQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>(AutocompleteSearchIdoitObjectTypesDocument, variables, options);
}
export type AutocompleteSearchIdoitObjectTypesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchIdoitObjectTypesQuery, Types.AutocompleteSearchIdoitObjectTypesQueryVariables>;