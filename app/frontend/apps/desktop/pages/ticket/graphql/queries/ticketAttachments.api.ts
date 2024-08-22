import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketAttachmentsQuery(variables: Types.TicketAttachmentsQueryVariables | VueCompositionApi.Ref<Types.TicketAttachmentsQueryVariables> | ReactiveFunction<Types.TicketAttachmentsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>(TicketAttachmentsDocument, variables, options);
}
export function useTicketAttachmentsLazyQuery(variables?: Types.TicketAttachmentsQueryVariables | VueCompositionApi.Ref<Types.TicketAttachmentsQueryVariables> | ReactiveFunction<Types.TicketAttachmentsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>(TicketAttachmentsDocument, variables, options);
}
export type TicketAttachmentsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>;