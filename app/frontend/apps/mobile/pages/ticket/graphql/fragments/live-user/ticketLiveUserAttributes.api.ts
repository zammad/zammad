import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
export const TicketLiveUserAttributesFragmentDoc = gql`
    fragment ticketLiveUserAttributes on TicketLiveUser {
  user {
    id
    firstname
    lastname
    fullname
    email
    vip
    outOfOffice
    active
    image
  }
  apps {
    name
    editing
    lastInteraction
  }
}
    `;