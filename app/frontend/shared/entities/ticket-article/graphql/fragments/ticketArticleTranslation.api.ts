import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TicketArticleTranslationFragmentDoc = gql`
    fragment ticketArticleTranslation on TicketArticle {
  id
  translation(targetLocale: $targetLocale) {
    content
    backend
    translated
  }
}
    `;