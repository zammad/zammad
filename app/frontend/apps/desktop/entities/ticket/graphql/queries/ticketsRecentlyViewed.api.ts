import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SimpleTicketAttributeFragmentDoc } from '../../../../../../shared/graphql/fragments/simpleTicketAttribute.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketsRecentlyViewedDocument = gql`
    query ticketsRecentlyViewed($limit: Int) {
  ticketsRecentlyViewed(limit: $limit) {
    ...simpleTicketAttribute
  }
}
    ${SimpleTicketAttributeFragmentDoc}`;
export function useTicketsRecentlyViewedQuery(options: VueApolloComposable.useQuery.Options<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>(TicketsRecentlyViewedDocument, options);
}
export function useTicketsRecentlyViewedLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>(TicketsRecentlyViewedDocument, options);
}
export type TicketsRecentlyViewedQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>;