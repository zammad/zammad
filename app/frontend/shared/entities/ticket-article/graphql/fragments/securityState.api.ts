import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const SecurityStateFragmentDoc = gql`
    fragment securityState on TicketArticleSecurityState {
  type
  signingSuccess
  signingMessage
  encryptionSuccess
  encryptionMessage
}
    `;