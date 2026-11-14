import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { TicketMentionFragmentDoc } from '../fragments/ticketMention.api';
import { ReferencingTicketFragmentDoc } from '../fragments/referencingTicket.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketDocument = gql`
    query ticket($ticketId: ID!) {
  ticket(ticketId: $ticketId) {
    ...ticketAttributes
    aiSummaryEnabled
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
${ObjectAttributeValuesFragmentDoc}
${TicketMentionFragmentDoc}
${ReferencingTicketFragmentDoc}`;
export function useTicketQuery(options: VueApolloComposable.useQuery.Options<Types.TicketQuery, Types.TicketQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketQuery, Types.TicketQueryVariables>(TicketDocument, options);
}
export function useTicketLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketQuery, Types.TicketQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketQuery, Types.TicketQueryVariables>(TicketDocument, options);
}
export type TicketQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketQuery, Types.TicketQueryVariables>;