import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SearchCountsDocument = gql`
    query searchCounts($search: String!, $onlyIn: [EnumSearchableModels!]!, $filters: [SelectorObjectInput!]) {
  searchCounts(search: $search, onlyIn: $onlyIn, filters: $filters) {
    model
    totalCount
  }
}
    `;
export function useSearchCountsQuery(options: VueApolloComposable.useQuery.Options<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>(SearchCountsDocument, options);
}
export function useSearchCountsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>(SearchCountsDocument, options);
}
export type SearchCountsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>;