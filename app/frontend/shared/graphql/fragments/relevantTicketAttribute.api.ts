import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const RelevantTicketAttributeFragmentDoc = gql`
    fragment relevantTicketAttribute on Ticket {
  number
  internalId
  id
  title
  customer {
    fullname
  }
  organization {
    name
  }
  group {
    name
  }
  createdAt
  stateColorCode
  state {
    name
  }
}
    `;