import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseAnswerTranslationFragmentDoc = gql`
    fragment knowledgeBaseAnswerTranslation on KnowledgeBaseAnswerTranslation {
  id
  title
  maybeLocale
  visibility
  categoryTreeTranslation {
    id
    title
  }
  content {
    id
    bodyExcerpt
  }
  answer {
    id
    archivedAt
    publishedAt
    internalAt
    tags
    category {
      id
    }
  }
  kbLocale {
    systemLocale {
      locale
      name
    }
  }
}
    `;