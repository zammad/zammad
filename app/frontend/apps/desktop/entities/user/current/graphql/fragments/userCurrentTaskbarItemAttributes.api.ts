import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketTaskbarTabAttributesFragmentDoc } from '../../../../../../../shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api';
export const UserCurrentTaskbarItemAttributesFragmentDoc = gql`
    fragment userCurrentTaskbarItemAttributes on UserTaskbarItem {
  id
  key
  callback
  formId
  formNewArticlePresent
  entity {
    ... on Ticket {
      ...ticketTaskbarTabAttributes
    }
    ... on UserTaskbarItemEntityTicketCreate {
      uid
      title
      createArticleTypeKey
    }
    ... on UserTaskbarItemEntitySearch {
      query
      model
    }
    ... on User {
      id
      internalId
    }
    ... on Organization {
      id
      internalId
    }
  }
  entityAccess
  prio
  changed
  dirty
  notify
  updatedAt
}
    ${TicketTaskbarTabAttributesFragmentDoc}`;