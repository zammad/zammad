import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TicketSharedDraftStartAttributesFragmentDoc = gql`
    fragment ticketSharedDraftStartAttributes on TicketSharedDraftStart {
  id
  name
  content
}
    `;