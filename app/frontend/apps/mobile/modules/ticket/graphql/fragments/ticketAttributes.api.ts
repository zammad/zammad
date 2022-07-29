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
    name
    stateType {
      name
    }
  }
  group {
    name
  }
  priority {
    name
    defaultCreate
    uiColor
  }
}
    `;