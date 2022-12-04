import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
export const TicketMentionFragmentDoc = gql`
    fragment ticketMention on Mention {
  user {
    id
    internalId
    firstname
    lastname
    fullname
    vip
    outOfOffice
    active
    image
  }
}
    `;