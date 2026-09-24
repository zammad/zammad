import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TicketArticleTranslationAvailabilityFragmentDoc = gql`
    fragment ticketArticleTranslationAvailability on TicketArticle {
  id
  translationAvailable(targetLocale: $targetLocale)
}
    `;