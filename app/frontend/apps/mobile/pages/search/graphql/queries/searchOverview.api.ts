import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SearchDocument = gql`
    query search($search: String!, $onlyIn: EnumSearchableModels, $limit: Int = 30) {
  search(search: $search, onlyIn: $onlyIn, limit: $limit) {
    ... on Ticket {
      id
      internalId
      title
      number
      state {
        name
      }
      priority {
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
      updatedBy {
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
      outOfOfficeStartAt
      outOfOfficeEndAt
      vip
      organization {
        id
        internalId
        name
      }
      updatedAt
      updatedBy {
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
      vip
      updatedAt
      updatedBy {
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
export function useSearchLazyQuery(variables?: Types.SearchQueryVariables | VueCompositionApi.Ref<Types.SearchQueryVariables> | ReactiveFunction<Types.SearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SearchQuery, Types.SearchQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.SearchQuery, Types.SearchQueryVariables>(SearchDocument, variables, options);
}
export type SearchQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SearchQuery, Types.SearchQueryVariables>;