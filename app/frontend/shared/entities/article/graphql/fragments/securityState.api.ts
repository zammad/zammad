import * as Types from '../../../../graphql/types';

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