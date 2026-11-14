import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketSharedDraftStartSingleDocument = gql`
    query ticketSharedDraftStartSingle($sharedDraftId: ID!) {
  ticketSharedDraftStartSingle(sharedDraftId: $sharedDraftId) {
    ...ticketSharedDraftStartAttributes
    content
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}`;
export function useTicketSharedDraftStartSingleQuery(options: VueApolloComposable.useQuery.Options<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>(TicketSharedDraftStartSingleDocument, options);
}
export function useTicketSharedDraftStartSingleLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>(TicketSharedDraftStartSingleDocument, options);
}
export type TicketSharedDraftStartSingleQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>;