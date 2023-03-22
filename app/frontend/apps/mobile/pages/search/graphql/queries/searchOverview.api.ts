import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SearchDocument = gql`
    query search($search: String!, $isAgent: Boolean!, $onlyIn: EnumSearchableModels, $limit: Int = 30) {
  search(search: $search, onlyIn: $onlyIn, limit: $limit) {
    ... on Ticket {
      id
      internalId
      title
      number
      state {
        name
      }
      priority @include(if: $isAgent) {
        name
        defaultCreate
        uiColor
      }
      customer {
        id
        internalId
        fullname
      }
      updatedAt
      updatedBy @include(if: $isAgent) {
        id
        fullname
      }
      stateColorCode
    }
    ... on User {
      id
      internalId
      firstname
      lastname
      image
      active
      outOfOffice
      vip
      organization {
        id
        internalId
        name
      }
      updatedAt
      updatedBy @include(if: $isAgent) {
        id
        fullname
      }
      ticketsCount {
        open
        closed
      }
    }
    ... on Organization {
      id
      internalId
      members(first: 2) {
        edges {
          node {
            id
            fullname
          }
        }
        totalCount
      }
      active
      name
      updatedAt
      updatedBy @include(if: $isAgent) {
        id
        fullname
      }
      ticketsCount {
        open
        closed
      }
    }
  }
}
    `;
export function useSearchQuery(variables: Types.SearchQueryVariables | VueCompositionApi.Ref<Types.SearchQueryVariables> | ReactiveFunction<Types.SearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.SearchQuery, Types.SearchQueryVariables>(SearchDocument, variables, options);
}
export function useSearchLazyQuery(variables: Types.SearchQueryVariables | VueCompositionApi.Ref<Types.SearchQueryVariables> | ReactiveFunction<Types.SearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.SearchQuery, Types.SearchQueryVariables>(SearchDocument, variables, options);
}
export type SearchQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SearchQuery, Types.SearchQueryVariables>;