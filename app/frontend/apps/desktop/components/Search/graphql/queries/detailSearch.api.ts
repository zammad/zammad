import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const DetailSearchDocument = gql`
    query detailSearch($search: String!, $onlyIn: EnumSearchableModels!, $filter: SelectorNodeInput, $limit: Int = 30, $offset: Int, $orderBy: String, $orderDirection: EnumOrderDirection) {
  search(
    search: $search
    onlyIn: $onlyIn
    filter: $filter
    limit: $limit
    offset: $offset
    orderBy: $orderBy
    orderDirection: $orderDirection
  ) {
    totalCount
    items {
      __typename
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
      ... on ChatSession {
        id
        internalId
        name
        sessionState: state
        createdAt
      }
      ... on KnowledgeBaseAnswerTranslation {
        id
        title
        updatedAt
        visibility
        answer {
          id
          category {
            id
          }
        }
        kbLocale {
          systemLocale {
            locale
          }
        }
      }
    }
  }
}
    `;
export function useDetailSearchQuery(options: VueApolloComposable.useQuery.Options<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>) {
  return VueApolloComposable.useQuery<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>(DetailSearchDocument, options);
}
export function useDetailSearchLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>(DetailSearchDocument, options);
}
export type DetailSearchQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>;