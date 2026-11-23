import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketArticleAttributesFragmentDoc } from '../fragments/ticketArticleAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticleUpdatesDocument = gql`
    subscription ticketArticleUpdates($ticketId: ID!) {
  ticketArticleUpdates(ticketId: $ticketId) {
    addArticle {
      id
      createdAt
      sender {
        name
      }
    }
    updateArticle {
      ...ticketArticleAttributes
    }
    removeArticleId
    refetchArticles
  }
}
    ${TicketArticleAttributesFragmentDoc}`;
export function useTicketArticleUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables>(TicketArticleUpdatesDocument, options);
}
export type TicketArticleUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketArticleUpdatesSubscription, Types.TicketArticleUpdatesSubscriptionVariables>;