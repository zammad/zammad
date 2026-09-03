import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketTaskbarTabAttributesFragmentDoc } from '../../../../../../../shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api';
import { KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc } from '../../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTaskbarTabAttributes.api';
export const UserCurrentTaskbarItemAttributesFragmentDoc = gql`
    fragment userCurrentTaskbarItemAttributes on UserTaskbarItem {
  id
  key
  callback
  formId
  formNewArticlePresent
  entity {
    __typename
    ... on Ticket {
      ...ticketTaskbarTabAttributes
    }
    ... on KnowledgeBaseAnswerTranslation {
      ...knowledgeBaseAnswerTaskbarTabAttributes
    }
    ... on UserTaskbarItemEntityTicketCreate {
      uid
      title
      createArticleTypeKey
    }
    ... on UserTaskbarItemEntityKnowledgeBaseAnswerCreate {
      uid
      title
      locale
      visibility
    }
    ... on UserTaskbarItemEntitySearch {
      query
      model
      filters
      filterCount
    }
    ... on User {
      id
      internalId
      fullname
      active
    }
    ... on Organization {
      id
      internalId
      name
      active
    }
  }
  entityAccess
  prio
  changed
  dirty
  notify
  updatedAt
}
    ${TicketTaskbarTabAttributesFragmentDoc}
${KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc}`;