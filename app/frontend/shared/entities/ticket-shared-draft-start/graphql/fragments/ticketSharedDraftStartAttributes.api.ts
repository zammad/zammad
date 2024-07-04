import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TicketSharedDraftStartAttributesFragmentDoc = gql`
    fragment ticketSharedDraftStartAttributes on TicketSharedDraftStart {
  id
  name
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