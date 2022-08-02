import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
export const TicketAttributesFragmentDoc = gql`
    fragment ticketAttributes on Ticket {
  id
  internalId
  number
  title
  createdAt
  updatedAt
  owner {
    id
    firstname
    lastname
  }
  customer {
    id
    firstname
    lastname
    fullname
  }
  organization {
    name
  }
  state {
    id
    name
    stateType {
      name
    }
  }
  group {
    id
    name
  }
  priority {
    id
    name
    defaultCreate
    uiColor
  }
}
    `;