import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { TicketMentionFragmentDoc } from '../fragments/ticketMention.api';
import { ReferencingTicketFragmentDoc } from '../fragments/referencingTicket.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketDocument = gql`
    query ticket($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
  ticket(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
  ) {
    ...ticketAttributes
    createArticleType {
      id
      name
    }
    mentions(first: 20) {
      totalCount
      edges {
        node {
          ...ticketMention
        }
        cursor
      }
    }
    checklist {
      id
      completed
      incomplete
      total
      complete
    }
    referencingChecklistTickets {
      ...referencingTicket
    }
  }
}
    ${TicketAttributesFragmentDoc}
${TicketMentionFragmentDoc}
${ReferencingTicketFragmentDoc}`;
export function useTicketQuery(variables: Types.TicketQueryVariables | VueCompositionApi.Ref<Types.TicketQueryVariables> | ReactiveFunction<Types.TicketQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketQuery, Types.TicketQueryVariables>(TicketDocument, variables, options);
}
export function useTicketLazyQuery(variables: Types.TicketQueryVariables | VueCompositionApi.Ref<Types.TicketQueryVariables> | ReactiveFunction<Types.TicketQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketQuery, Types.TicketQueryVariables>(TicketDocument, variables, options);
}
export type TicketQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketQuery, Types.TicketQueryVariables>;