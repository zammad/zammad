import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { TicketArticleAttributesFragmentDoc } from '../fragments/ticketArticleAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketUpdatesDocument = gql`
    subscription ticketUpdates($ticketId: ID!, $withArticles: Boolean = false, $withObjectAttributes: Boolean = false) {
  ticketUpdates(ticketId: $ticketId) {
    ticket {
      ...ticketAttributes
      articles @include(if: $withArticles) {
        edges {
          node {
            ...ticketArticleAttributes
          }
        }
      }
      objectAttributeValues @include(if: $withObjectAttributes) {
        ...objectAttributeValues
      }
    }
  }
}
    ${TicketAttributesFragmentDoc}
${TicketArticleAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useTicketUpdatesSubscription(variables: Types.TicketUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>(TicketUpdatesDocument, variables, options);
}
export type TicketUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketUpdatesSubscription, Types.TicketUpdatesSubscriptionVariables>;