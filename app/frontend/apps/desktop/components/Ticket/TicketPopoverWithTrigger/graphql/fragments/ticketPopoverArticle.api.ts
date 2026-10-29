import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TicketPopoverArticleFragmentDoc = gql`
    fragment ticketPopoverArticle on TicketArticle {
  id
  createdAt
  bodyExcerpt
  internal
  author {
    id
    fullname
    firstname
    lastname
    image
  }
  sender {
    name
  }
}
    `;