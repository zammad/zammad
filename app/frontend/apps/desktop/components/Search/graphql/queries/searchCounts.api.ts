import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SearchCountsDocument = gql`
    query searchCounts($search: String!, $onlyIn: [EnumSearchableModels!]!) {
  searchCounts(search: $search, onlyIn: $onlyIn) {
    model
    totalCount
  }
}
    `;
export function useSearchCountsQuery(variables: Types.SearchCountsQueryVariables | VueCompositionApi.Ref<Types.SearchCountsQueryVariables> | ReactiveFunction<Types.SearchCountsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.SearchCountsQuery, Types.SearchCountsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>(SearchCountsDocument, variables, options);
}
export function useSearchCountsLazyQuery(variables?: Types.SearchCountsQueryVariables | VueCompositionApi.Ref<Types.SearchCountsQueryVariables> | ReactiveFunction<Types.SearchCountsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.SearchCountsQuery, Types.SearchCountsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>(SearchCountsDocument, variables, options);
}
export type SearchCountsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>;