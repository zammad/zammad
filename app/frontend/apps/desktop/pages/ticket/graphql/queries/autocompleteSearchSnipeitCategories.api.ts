import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchSnipeitCategoriesDocument = gql`
    query autocompleteSearchSnipeitCategories($input: AutocompleteSearchInput!) {
  autocompleteSearchSnipeitCategories(input: $input) {
    value
    label
  }
}
    `;
export function useAutocompleteSearchSnipeitCategoriesQuery(variables: Types.AutocompleteSearchSnipeitCategoriesQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchSnipeitCategoriesQueryVariables> | ReactiveFunction<Types.AutocompleteSearchSnipeitCategoriesQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>(AutocompleteSearchSnipeitCategoriesDocument, variables, options);
}
export function useAutocompleteSearchSnipeitCategoriesLazyQuery(variables?: Types.AutocompleteSearchSnipeitCategoriesQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchSnipeitCategoriesQueryVariables> | ReactiveFunction<Types.AutocompleteSearchSnipeitCategoriesQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>(AutocompleteSearchSnipeitCategoriesDocument, variables, options);
}
export type AutocompleteSearchSnipeitCategoriesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchSnipeitCategoriesQuery, Types.AutocompleteSearchSnipeitCategoriesQueryVariables>;
