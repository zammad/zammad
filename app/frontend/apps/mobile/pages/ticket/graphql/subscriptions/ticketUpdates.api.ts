import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { TicketMentionFragmentDoc } from '../fragments/ticketMention.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketUpdatesDocument = gql`
    subscription ticketUpdates($ticketId: ID!) {
  ticketUpdates(ticketId: $ticketId) {
    ticket {
      ...ticketAttributes
      articleCount
      mentions {
        totalCount
        edges {
          node {
            ...ticketMention
          }
          cursor
        }
      }
    }
  }
}
    ${TicketAttributesFragmentDoc}
${TicketMentionFragmentDoc}`;
export function useTicketUpdatesSubscription(variables: Types.TicketUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>(TicketUpdatesDocument, variables, options);
}
export type TicketUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>;