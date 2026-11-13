import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketOverviewOrderDocument = gql`
    query ticketOverviewOrder($withTicketCount: Boolean = false) {
  ticketOverviews(ignoreUserConditions: true) {
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
export function useTicketOverviewOrderQuery(options: VueApolloComposable.useQuery.Options<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>(TicketOverviewOrderDocument, options);
}
export function useTicketOverviewOrderLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>(TicketOverviewOrderDocument, options);
}
export type TicketOverviewOrderQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>;