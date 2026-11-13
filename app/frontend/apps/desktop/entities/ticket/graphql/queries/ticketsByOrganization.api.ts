import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketsByOrganizationQuery(options: VueApolloComposable.useQuery.Options<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>(TicketsByOrganizationDocument, options);
}
export function useTicketsByOrganizationLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>(TicketsByOrganizationDocument, options);
}
export type TicketsByOrganizationQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketsByOrganizationQuery, Types.TicketsByOrganizationQueryVariables>;