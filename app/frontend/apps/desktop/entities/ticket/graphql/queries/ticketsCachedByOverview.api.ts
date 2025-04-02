import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketsCachedByOverviewDocument = gql`
    query ticketsCachedByOverview($overviewId: ID!, $orderBy: String, $orderDirection: EnumOrderDirection, $cursor: String, $pageSize: Int = 25, $cacheTtl: Int!, $renewCache: Boolean, $knownCollectionSignature: String) {
  ticketsCachedByOverview(
    overviewId: $overviewId
    orderBy: $orderBy
    orderDirection: $orderDirection
    after: $cursor
    first: $pageSize
    cacheTtl: $cacheTtl
    renewCache: $renewCache
    knownCollectionSignature: $knownCollectionSignature
  ) {
    totalCount
    edges {
      node {
        id
        internalId
        number
        title
        createdAt
        createdBy {
          id
          fullname
        }
        updatedAt
        updatedBy {
          id
          fullname
        }
        owner {
          id
          fullname
        }
        customer {
          id
          fullname
        }
        organization {
          id
          name
        }
        state {
          id
          name
          stateType {
            id
            name
          }
        }
        pendingTime
        group {
          id
          name
        }
        priority {
          id
          name
          uiColor
        }
        objectAttributeValues {
          ...objectAttributeValues
        }
        articleCount
        stateColorCode
        escalationAt
        firstResponseEscalationAt
        updateEscalationAt
        closeEscalationAt
        firstResponseAt
        closeAt
        timeUnit
        lastCloseAt
        lastContactAt
        lastContactAgentAt
        lastContactCustomerAt
        policy {
          update
        }
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
    collectionSignature
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;
export function useTicketsCachedByOverviewQuery(variables: Types.TicketsCachedByOverviewQueryVariables | VueCompositionApi.Ref<Types.TicketsCachedByOverviewQueryVariables> | ReactiveFunction<Types.TicketsCachedByOverviewQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>(TicketsCachedByOverviewDocument, variables, options);
}
export function useTicketsCachedByOverviewLazyQuery(variables?: Types.TicketsCachedByOverviewQueryVariables | VueCompositionApi.Ref<Types.TicketsCachedByOverviewQueryVariables> | ReactiveFunction<Types.TicketsCachedByOverviewQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>(TicketsCachedByOverviewDocument, variables, options);
}
export type TicketsCachedByOverviewQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>;