import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
export const TicketArticleAttributesFragmentDoc = gql`
    fragment ticketArticleAttributes on TicketArticle {
  id
  internalId
  from {
    raw
    parsed {
      name
      emailAddress
      isSystemAddress
    }
  }
  messageId
  to {
    raw
    parsed {
      name
      emailAddress
      isSystemAddress
    }
  }
  cc {
    raw
    parsed {
      name
      emailAddress
      isSystemAddress
    }
  }
  subject
  replyTo {
    raw
    parsed {
      name
      emailAddress
      isSystemAddress
    }
  }
  messageId
  messageIdMd5
  inReplyTo
  contentType
  references
  attachmentsWithoutInline {
    internalId
    name
    size
    type
    preferences
  }
  preferences
  bodyWithUrls
  internal
  createdAt
  originBy {
    id
    fullname
  }
  createdBy {
    id
    fullname
    firstname
    lastname
    email
    authorizations {
      provider
      uid
      username
    }
  }
  type {
    name
    communication
  }
  sender {
    name
  }
  securityState {
    encryptionMessage
    encryptionSuccess
    signingMessage
    signingSuccess
    type
  }
}
    `;