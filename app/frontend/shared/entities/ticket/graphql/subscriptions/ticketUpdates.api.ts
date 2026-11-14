import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { TicketMentionFragmentDoc } from '../fragments/ticketMention.api';
import { ReferencingTicketFragmentDoc } from '../fragments/referencingTicket.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketUpdatesDocument = gql`
    subscription ticketUpdates($ticketId: ID!, $initial: Boolean = false) {
  ticketUpdates(ticketId: $ticketId, initial: $initial) {
    ticket {
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
}
    ${TicketAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}
${TicketMentionFragmentDoc}
${ReferencingTicketFragmentDoc}`;
export function useTicketUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>(TicketUpdatesDocument, options);
}
export type TicketUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>;