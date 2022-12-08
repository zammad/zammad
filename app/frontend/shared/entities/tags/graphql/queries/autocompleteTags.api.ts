import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchTagDocument = gql`
    query autocompleteSearchTag($input: AutocompleteSearchInput!) {
  autocompleteSearchTag(input: $input) {
    value
    label
  }
}
    `;
export function useAutocompleteSearchTagQuery(variables: Types.AutocompleteSearchTagQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchTagQueryVariables> | ReactiveFunction<Types.AutocompleteSearchTagQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>(AutocompleteSearchTagDocument, variables, options);
}
export function useAutocompleteSearchTagLazyQuery(variables: Types.AutocompleteSearchTagQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchTagQueryVariables> | ReactiveFunction<Types.AutocompleteSearchTagQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>(AutocompleteSearchTagDocument, variables, options);
}
export type AutocompleteSearchTagQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchTagQuery, Types.AutocompleteSearchTagQueryVariables>;