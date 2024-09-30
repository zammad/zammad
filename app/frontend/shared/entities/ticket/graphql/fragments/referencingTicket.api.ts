import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ReferencingTicketFragmentDoc = gql`
    fragment referencingTicket on Ticket {
  id
  internalId
  number
  title
  state {
    id
    name
  }
  stateColorCode
}
    `;