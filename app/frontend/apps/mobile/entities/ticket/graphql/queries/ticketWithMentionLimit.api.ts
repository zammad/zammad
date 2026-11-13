import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/ticketAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import { TicketMentionFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/ticketMention.api';
import { ReferencingTicketFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/referencingTicket.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketWithMentionLimitDocument = gql`
    query ticketWithMentionLimit($ticketId: ID!, $mentionsCount: Int = null) {
  ticket(ticketId: $ticketId) {
    ...ticketAttributes
    aiSummaryEnabled
    createArticleType {
      id
      name
    }
    mentions(first: $mentionsCount) {
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
export function useTicketWithMentionLimitQuery(options: VueApolloComposable.useQuery.Options<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>(TicketWithMentionLimitDocument, options);
}
export function useTicketWithMentionLimitLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>(TicketWithMentionLimitDocument, options);
}
export type TicketWithMentionLimitQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>;