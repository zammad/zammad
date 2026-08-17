import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseAnswerAttributesFragmentDoc = gql`
    fragment knowledgeBaseAnswerAttributes on KnowledgeBaseAnswer {
  title
  content {
    id
    bodyWithUrls
  }
  visibility
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
    `;