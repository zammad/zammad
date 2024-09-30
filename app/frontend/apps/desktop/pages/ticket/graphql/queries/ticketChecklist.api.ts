import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ReferencingTicketFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/referencingTicket.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketChecklistDocument = gql`
    query ticketChecklist($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
  ticketChecklist(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
  ) {
    id
    name
    completed
    incomplete
    items {
      id
      text
      checked
      ticketReference {
        ticket {
          ...referencingTicket
        }
      }
    }
  }
}
    ${ReferencingTicketFragmentDoc}`;
export function useTicketChecklistQuery(variables: Types.TicketChecklistQueryVariables | VueCompositionApi.Ref<Types.TicketChecklistQueryVariables> | ReactiveFunction<Types.TicketChecklistQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>(TicketChecklistDocument, variables, options);
}
export function useTicketChecklistLazyQuery(variables: Types.TicketChecklistQueryVariables | VueCompositionApi.Ref<Types.TicketChecklistQueryVariables> | ReactiveFunction<Types.TicketChecklistQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>(TicketChecklistDocument, variables, options);
}
export type TicketChecklistQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>;