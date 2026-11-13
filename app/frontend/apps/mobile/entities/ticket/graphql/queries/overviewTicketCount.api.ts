import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketOverviewTicketCountDocument = gql`
    query ticketOverviewTicketCount($ignoreUserConditions: Boolean!) {
  ticketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    id
    ticketCount
  }
}
    `;
export function useTicketOverviewTicketCountQuery(options: VueApolloComposable.useQuery.Options<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>(TicketOverviewTicketCountDocument, options);
}
export function useTicketOverviewTicketCountLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>(TicketOverviewTicketCountDocument, options);
}
export type TicketOverviewTicketCountQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>;