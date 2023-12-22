import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketArticleAttributesFragmentDoc } from '../fragments/ticketArticleAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleUpdatesDocument = gql`
    subscription ticketArticleUpdates($ticketId: ID!) {
  ticketArticleUpdates(ticketId: $ticketId) {
    addArticle {
      id
      createdAt
    }
    updateArticle {
      ...ticketArticleAttributes
    }
    removeArticleId
  }
}
    ${TicketArticleAttributesFragmentDoc}`;
export function useTicketArticleUpdatesSubscription(variables: Types.TicketArticleUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketArticleUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketArticleUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables>(TicketArticleUpdatesDocument, variables, options);
}
export type TicketArticleUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables>;