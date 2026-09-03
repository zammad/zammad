import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc = gql`
    fragment knowledgeBaseAnswerTaskbarTabAttributes on KnowledgeBaseAnswerTranslation {
  id
  title
  kbLocale {
    id
    systemLocale {
      locale
    }
  }
  visibility
}
    `;