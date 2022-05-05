import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketsByOverviewQuery(variables: Types.TicketsByOverviewQueryVariables | VueCompositionApi.Ref<Types.TicketsByOverviewQueryVariables> | ReactiveFunction<Types.TicketsByOverviewQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>(TicketsByOverviewDocument, variables, options);
}
export function useTicketsByOverviewLazyQuery(variables: Types.TicketsByOverviewQueryVariables | VueCompositionApi.Ref<Types.TicketsByOverviewQueryVariables> | ReactiveFunction<Types.TicketsByOverviewQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>(TicketsByOverviewDocument, variables, options);
}
export type TicketsByOverviewQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByOverviewQuery, Types.TicketsByOverviewQueryVariables>;