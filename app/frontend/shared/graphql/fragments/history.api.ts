import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const HistoryIssuerFragmentDoc = gql`
    fragment HistoryIssuer on HistoryRecordIssuer {
  ... on User {
    id
    internalId
    firstname
    lastname
    fullname
    phone
    email
    image
  }
  ... on Trigger {
    id
    name
  }
  ... on Job {
    id
    name
  }
  ... on PostmasterFilter {
    id
    name
  }
  ... on AIAgent {
    id
    name
  }
  ... on Macro {
    id
    name
  }
  ... on ObjectClass {
    klass
    info
  }
}
    `;
export const HistoryEventObjectFragmentDoc = gql`
    fragment HistoryEventObject on HistoryRecordEventObject {
  ... on Checklist {
    id
    name
  }
  ... on ChecklistItem {
    id
    text
    checked
  }
  ... on Group {
    id
    name
  }
  ... on Mention {
    id
    user {
      id
      fullname
    }
  }
  ... on Organization {
    id
    name
  }
  ... on Ticket {
    id
    internalId
    number
    title
  }
  ... on TicketArticle {
    id
    body
  }
  ... on TicketSharedDraftZoom {
    id
  }
  ... on User {
    id
    fullname
  }
  ... on ObjectClass {
    klass
    info
  }
}
    `;
export const HistoryEventFragmentDoc = gql`
    fragment HistoryEvent on HistoryRecordEvent {
  createdAt
  action
  object {
    ...HistoryEventObject
  }
  attribute
  changes
}
    ${HistoryEventObjectFragmentDoc}`;
export const HistoryGroupFragmentDoc = gql`
    fragment HistoryGroup on HistoryGroup {
  createdAt
  records {
    issuer {
      ...HistoryIssuer
    }
    events {
      ...HistoryEvent
    }
  }
}
    ${HistoryIssuerFragmentDoc}
${HistoryEventFragmentDoc}`;