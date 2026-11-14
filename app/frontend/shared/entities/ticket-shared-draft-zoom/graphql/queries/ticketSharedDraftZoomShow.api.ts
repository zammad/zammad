import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftZoomAttributesFragmentDoc } from '../fragments/ticketSharedDraftZoomAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketSharedDraftZoomShowDocument = gql`
    query ticketSharedDraftZoomShow($sharedDraftId: ID!) {
  ticketSharedDraftZoomShow(sharedDraftId: $sharedDraftId) {
    ...ticketSharedDraftZoomAttributes
  }
}
    ${TicketSharedDraftZoomAttributesFragmentDoc}`;
export function useTicketSharedDraftZoomShowQuery(options: VueApolloComposable.useQuery.Options<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>(TicketSharedDraftZoomShowDocument, options);
}
export function useTicketSharedDraftZoomShowLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>(TicketSharedDraftZoomShowDocument, options);
}
export type TicketSharedDraftZoomShowQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>;