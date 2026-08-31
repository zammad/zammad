import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchSnipeitModelsDocument = gql`
    query autocompleteSearchSnipeitModels($input: AutocompleteSearchSnipeitModelsInput!) {
  autocompleteSearchSnipeitModels(input: $input) {
    value
    label
  }
}
    `;
export function useAutocompleteSearchSnipeitModelsQuery(variables: Types.AutocompleteSearchSnipeitModelsQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchSnipeitModelsQueryVariables> | ReactiveFunction<Types.AutocompleteSearchSnipeitModelsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>(AutocompleteSearchSnipeitModelsDocument, variables, options);
}
export function useAutocompleteSearchSnipeitModelsLazyQuery(variables?: Types.AutocompleteSearchSnipeitModelsQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchSnipeitModelsQueryVariables> | ReactiveFunction<Types.AutocompleteSearchSnipeitModelsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>(AutocompleteSearchSnipeitModelsDocument, variables, options);
}
export type AutocompleteSearchSnipeitModelsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchSnipeitModelsQuery, Types.AutocompleteSearchSnipeitModelsQueryVariables>;