import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TicketTaskbarTabAttributesFragmentDoc = gql`
    fragment ticketTaskbarTabAttributes on Ticket {
  id
  internalId
  number
  title
  state {
    id
    name
  }
  stateColorCode
  updatedAt
}
    `;