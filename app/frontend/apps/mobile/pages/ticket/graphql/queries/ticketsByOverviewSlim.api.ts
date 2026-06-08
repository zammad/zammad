import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketsByOverviewSlimDocument = gql`
    query ticketsByOverviewSlim($overviewId: ID!, $orderBy: String, $orderDirection: EnumOrderDirection, $cursor: String, $showPriority: Boolean!, $showUpdatedBy: Boolean!, $pageSize: Int = 10, $withObjectAttributes: Boolean = false) {
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
        internalId
        number
        title
        createdAt
        updatedAt
        updatedBy @include(if: $showUpdatedBy) {
          id
          fullname
        }
        customer {
          id
          firstname
          lastname
          fullname
        }
        organization {
          id
          name
        }
        aiAgentRunning
        state {
          id
          name
          stateType {
            id
            name
          }
        }
        group {
          id
          name
        }
        priority @include(if: $showPriority) {
          id
          name
          uiColor
          defaultCreate
        }
        objectAttributeValues @include(if: $withObjectAttributes) {
          ...objectAttributeValues
        }
        stateColorCode
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
export function useTicketsByOverviewSlimQuery(variables: Types.TicketsByOverviewSlimQueryVariables | VueCompositionApi.Ref<Types.TicketsByOverviewSlimQueryVariables> | ReactiveFunction<Types.TicketsByOverviewSlimQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>(TicketsByOverviewSlimDocument, variables, options);
}
export function useTicketsByOverviewSlimLazyQuery(variables?: Types.TicketsByOverviewSlimQueryVariables | VueCompositionApi.Ref<Types.TicketsByOverviewSlimQueryVariables> | ReactiveFunction<Types.TicketsByOverviewSlimQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>(TicketsByOverviewSlimDocument, variables, options);
}
export type TicketsByOverviewSlimQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByOverviewSlimQuery, Types.TicketsByOverviewSlimQueryVariables>;