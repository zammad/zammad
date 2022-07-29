import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
export const TicketArticleAttributesFragmentDoc = gql`
    fragment ticketArticleAttributes on TicketArticle {
  id
  internal
  body
  createdAt
  createdBy {
    id
    firstname
    lastname
  }
  sender {
    name
  }
  subject
  to {
    raw
    parsed {
      name
      emailAddress
    }
  }
  internal
}
    `;