import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const DetailSearchDocument = gql`
    query detailSearch($search: String!, $onlyIn: EnumSearchableModels!, $limit: Int = 30, $offset: Int, $orderBy: String, $orderDirection: EnumOrderDirection) {
  search(
    search: $search
    onlyIn: $onlyIn
    limit: $limit
    offset: $offset
    orderBy: $orderBy
    orderDirection: $orderDirection
  ) {
    totalCount
    items {
      ... on Ticket {
        id
        internalId
        title
        number
        customer {
          id
          fullname
        }
        owner {
          id
          fullname
        }
        group {
          id
          name
        }
        state {
          id
          name
        }
        stateColorCode
        priority {
          id
          name
          uiColor
        }
        createdAt
        policy {
          update
        }
      }
      ... on User {
        id
        internalId
        login
        firstname
        lastname
        organization {
          id
          name
        }
        secondaryOrganizations(first: 3) {
          edges {
            node {
              id
              name
            }
          }
          totalCount
        }
        active
      }
      ... on Organization {
        id
        internalId
        name
        shared
        active
      }
    }
  }
}
    `;
export function useDetailSearchQuery(variables: Types.DetailSearchQueryVariables | VueCompositionApi.Ref<Types.DetailSearchQueryVariables> | ReactiveFunction<Types.DetailSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.DetailSearchQuery, Types.DetailSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>(DetailSearchDocument, variables, options);
}
export function useDetailSearchLazyQuery(variables?: Types.DetailSearchQueryVariables | VueCompositionApi.Ref<Types.DetailSearchQueryVariables> | ReactiveFunction<Types.DetailSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.DetailSearchQuery, Types.DetailSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>(DetailSearchDocument, variables, options);
}
export type DetailSearchQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>;