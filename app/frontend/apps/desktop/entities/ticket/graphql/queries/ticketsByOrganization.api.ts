import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketsByOrganizationDocument = gql`
    query ticketsByOrganization($organizationId: ID!, $stateTypeCategory: EnumTicketStateTypeCategory, $pageSize: Int = 7, $cursor: String) {
  ticketsByOrganization(
    organizationId: $organizationId
    stateTypeCategory: $stateTypeCategory
    first: $pageSize
    after: $cursor
  ) {
    totalCount
    edges {
      node {
        id
        internalId
        number
        title
        stateColorCode
        state {
          id
          name
        }
        createdAt
      }
    }
    pageInfo {
      endCursor
    }
  }
}
    `;
export function useTicketsByOrganizationQuery(variables: Types.TicketsByOrganizationQueryVariables | VueCompositionApi.Ref<Types.TicketsByOrganizationQueryVariables> | ReactiveFunction<Types.TicketsByOrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>(TicketsByOrganizationDocument, variables, options);
}
export function useTicketsByOrganizationLazyQuery(variables?: Types.TicketsByOrganizationQueryVariables | VueCompositionApi.Ref<Types.TicketsByOrganizationQueryVariables> | ReactiveFunction<Types.TicketsByOrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>(TicketsByOrganizationDocument, variables, options);
}
export type TicketsByOrganizationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>;