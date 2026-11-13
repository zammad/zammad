import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketOverviewsDocument = gql`
    query ticketOverviews($withTicketCount: Boolean!) {
  ticketOverviews(ignoreUserConditions: false) {
    ...overviewAttributes
    viewColumns {
      key
      value
    }
    orderColumns {
      key
      value
    }
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useTicketOverviewsQuery(options: VueApolloComposable.useQuery.Options<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>(TicketOverviewsDocument, options);
}
export function useTicketOverviewsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>(TicketOverviewsDocument, options);
}
export type TicketOverviewsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>;