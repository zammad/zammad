import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SearchDocument = gql`
    query search($search: String!, $onlyIn: EnumSearchableModels!, $limit: Int = 30) {
  search(search: $search, onlyIn: $onlyIn, limit: $limit) {
    totalCount
    items {
      __typename
      ... on Ticket {
        id
        internalId
        title
        number
        state {
          id
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
}
    `;
export function useSearchQuery(options: VueApolloComposable.useQuery.Options<Types.SearchQuery, Types.SearchQueryVariables>) {
  return VueApolloComposable.useQuery<Types.SearchQuery, Types.SearchQueryVariables>(SearchDocument, options);
}
export function useSearchLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.SearchQuery, Types.SearchQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.SearchQuery, Types.SearchQueryVariables>(SearchDocument, options);
}
export type SearchQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.SearchQuery, Types.SearchQueryVariables>;