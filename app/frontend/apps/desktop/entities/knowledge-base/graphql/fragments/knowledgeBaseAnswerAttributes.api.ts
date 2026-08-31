import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerPolicyFragmentDoc } from './knowledgeBaseAnswerPolicy.api';
export const KnowledgeBaseAnswerAttributesFragmentDoc = gql`
    fragment knowledgeBaseAnswerAttributes on KnowledgeBaseAnswer {
  ...knowledgeBaseAnswerPolicy
  title
  content {
    id
    bodyWithUrls
    bodyForEditing @include(if: $withBodyForEditing)
  }
  visibility
  visibilitySchedules {
    visibility
    scheduledAt
  }
  translationId
  translationMissing
  internalAt
  publishedAt
  archivedAt
  editedAt
  editedBy {
    id
    firstname
    lastname
    fullname
  }
  category {
    id
    breadcrumb {
      id
      title
      categoryIcon
      iconSet
      visibility
    }
  }
  tags
  attachments {
    id
    internalId
    name
    size
    type
    preferences
  }
}
    ${KnowledgeBaseAnswerPolicyFragmentDoc}`;