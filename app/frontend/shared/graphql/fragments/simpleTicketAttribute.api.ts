import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const SimpleTicketAttributeFragmentDoc = gql`
    fragment simpleTicketAttribute on Ticket {
  number
  internalId
  id
  title
  customer {
    id
    fullname
  }
  organization {
    id
    name
  }
  group {
    id
    name
  }
  createdAt
  stateColorCode
  state {
    id
    name
  }
}
    `;