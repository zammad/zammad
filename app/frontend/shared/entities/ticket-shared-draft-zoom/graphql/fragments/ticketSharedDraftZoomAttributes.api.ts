import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TicketSharedDraftZoomAttributesFragmentDoc = gql`
    fragment ticketSharedDraftZoomAttributes on TicketSharedDraftZoom {
  id
  ticketId
  newArticle
  ticketAttributes
  updatedAt
  updatedBy {
    id
    internalId
    firstname
    lastname
    fullname
    email
    phone
    image
    outOfOffice
    outOfOfficeStartAt
    outOfOfficeEndAt
    active
  }
}
    `;