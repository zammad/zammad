import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketAttachmentsDocument = gql`
    query ticketAttachments($ticketId: ID!) {
  ticketAttachments(ticketId: $ticketId) {
    id
    internalId
    name
    size
    type
    preferences
  }
}
    `;
export function useTicketAttachmentsQuery(options: VueApolloComposable.useQuery.Options<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>(TicketAttachmentsDocument, options);
}
export function useTicketAttachmentsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>(TicketAttachmentsDocument, options);
}
export type TicketAttachmentsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>;