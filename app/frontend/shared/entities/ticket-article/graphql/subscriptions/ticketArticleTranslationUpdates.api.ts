import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketArticleTranslationFragmentDoc } from '../fragments/ticketArticleTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticleTranslationUpdatesDocument = gql`
    subscription ticketArticleTranslationUpdates($ticketId: ID!, $targetLocale: String!) {
  ticketArticleTranslationUpdates(
    ticketId: $ticketId
    targetLocale: $targetLocale
  ) {
    article {
      ...ticketArticleTranslation
    }
    translation {
      translated
    }
    error {
      message
      exception
    }
    analytics {
      run {
        id
      }
      usage {
        userHasProvidedFeedback
      }
    }
  }
}
    ${TicketArticleTranslationFragmentDoc}`;
export function useTicketArticleTranslationUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables>(TicketArticleTranslationUpdatesDocument, options);
}
export type TicketArticleTranslationUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables>;