import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseAnswerTranslationFragmentDoc = gql`
    fragment knowledgeBaseAnswerTranslation on KnowledgeBaseAnswerTranslation {
  id
  title
  visibility
  categoryTreeTranslation {
    id
    title
  }
  content {
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
      title
      knowledgeBase {
        id
      }
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