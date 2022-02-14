import * as Types from '@common/graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;
export const ObjectAttributeValuesFragmentDoc = gql`
    fragment objectAttributeValues on ObjectAttributeValue {
  attribute {
    name
    display
    dataType
    dataOption
    screens
    editable
    active
  }
  value
}
    `;
export const TicketsByIdDocument = gql`
    query ticketsById($ticketId: ID!, $withArticles: Boolean = false, $withObjectAttributes: Boolean = false) {
  ticketById(ticketId: $ticketId) {
    id
    number
    title
    createdAt
    updatedAt
    owner {
      firstname
      lastname
    }
    customer {
      firstname
      lastname
    }
    organization {
      name
    }
    state {
      name
      stateType {
        name
      }
    }
    group {
      name
    }
    priority {
      name
    }
    articles @include(if: $withArticles) {
      edges {
        node {
          subject
        }
      }
    }
    objectAttributeValues @include(if: $withObjectAttributes) {
      ...objectAttributeValues
    }
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;

/**
 * __useTicketsByIdQuery__
 *
 * To run a query within a Vue component, call `useTicketsByIdQuery` and pass it any options that fit your needs.
 * When your component renders, `useTicketsByIdQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param variables that will be passed into the query
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useTicketsByIdQuery({
 *   ticketId: // value for 'ticketId'
 *   withArticles: // value for 'withArticles'
 *   withObjectAttributes: // value for 'withObjectAttributes'
 * });
 */
export function useTicketsByIdQuery(variables: Types.TicketsByIdQueryVariables | VueCompositionApi.Ref<Types.TicketsByIdQueryVariables> | ReactiveFunction<Types.TicketsByIdQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>(TicketsByIdDocument, variables, options);
}
export function useTicketsByIdLazyQuery(variables: Types.TicketsByIdQueryVariables | VueCompositionApi.Ref<Types.TicketsByIdQueryVariables> | ReactiveFunction<Types.TicketsByIdQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>(TicketsByIdDocument, variables, options);
}
export type TicketsByIdQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>;
export const TicketsByOverviewDocument = gql`
    query ticketsByOverview($overviewId: ID!, $orderBy: TicketOrderBy, $orderDirection: OrderDirection, $cursor: String, $pageSize: Int = 10, $withObjectAttributes: Boolean = false) {
  ticketsByOverview(
    overviewId: $overviewId
    orderBy: $orderBy
    orderDirection: $orderDirection
    after: $cursor
    first: $pageSize
  ) {
    totalCount
    edges {
      node {
        id
        number
        title
        createdAt
        updatedAt
        owner {
          firstname
          lastname
        }
        customer {
          firstname
          lastname
        }
        organization {
          name
        }
        state {
          name
          stateType {
            name
          }
        }
        group {
          name
        }
        priority {
          name
        }
        objectAttributeValues @include(if: $withObjectAttributes) {
          ...objectAttributeValues
        }
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;

/**
 * __useTicketsByOverviewQuery__
 *
 * To run a query within a Vue component, call `useTicketsByOverviewQuery` and pass it any options that fit your needs.
 * When your component renders, `useTicketsByOverviewQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param variables that will be passed into the query
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useTicketsByOverviewQuery({
 *   overviewId: // value for 'overviewId'
 *   orderBy: // value for 'orderBy'
 *   orderDirection: // value for 'orderDirection'
 *   cursor: // value for 'cursor'
 *   pageSize: // value for 'pageSize'
 *   withObjectAttributes: // value for 'withObjectAttributes'
 * });
 */
export function useTicketsByOverviewQuery(variables: Types.TicketsByOverviewQueryVariables | VueCompositionApi.Ref<Types.TicketsByOverviewQueryVariables> | ReactiveFunction<Types.TicketsByOverviewQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>(TicketsByOverviewDocument, variables, options);
}
export function useTicketsByOverviewLazyQuery(variables: Types.TicketsByOverviewQueryVariables | VueCompositionApi.Ref<Types.TicketsByOverviewQueryVariables> | ReactiveFunction<Types.TicketsByOverviewQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>(TicketsByOverviewDocument, variables, options);
}
export type TicketsByOverviewQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>;