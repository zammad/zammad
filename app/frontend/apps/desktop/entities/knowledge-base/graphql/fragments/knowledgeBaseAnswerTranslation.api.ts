import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseAnswerTranslationFragmentDoc = gql`
    fragment knowledgeBaseAnswerTranslation on KnowledgeBaseAnswerTranslation {
  id
  title
  visibility
  content {
    bodyExcerpt
  }
  answer {
    id
    archivedAt
    publishedAt
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