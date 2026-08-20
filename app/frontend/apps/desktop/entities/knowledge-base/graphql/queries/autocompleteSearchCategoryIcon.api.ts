import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchKnowledgeBaseCategoryIconDocument = gql`
    query autocompleteSearchKnowledgeBaseCategoryIcon($input: AutocompleteSearchKnowledgeBaseCategoryIconInput!) {
  autocompleteSearchKnowledgeBaseCategoryIcon(input: $input) {
    value
    label
    iconSet
  }
}
    `;
export function useAutocompleteSearchKnowledgeBaseCategoryIconQuery(variables: Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables> | ReactiveFunction<Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>(AutocompleteSearchKnowledgeBaseCategoryIconDocument, variables, options);
}
export function useAutocompleteSearchKnowledgeBaseCategoryIconLazyQuery(variables?: Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables> | ReactiveFunction<Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>(AutocompleteSearchKnowledgeBaseCategoryIconDocument, variables, options);
}
export type AutocompleteSearchKnowledgeBaseCategoryIconQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>;