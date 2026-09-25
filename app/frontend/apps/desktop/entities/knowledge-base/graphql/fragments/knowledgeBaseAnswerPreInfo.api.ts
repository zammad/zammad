import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseAnswerPreInfoFragmentDoc = gql`
    fragment knowledgeBaseAnswerPreInfo on KnowledgeBaseAnswer {
  visibility
  translation(locale: $locale) {
    id
    title
    kbLocale {
      id
      systemLocale {
        locale
      }
    }
  }
  category {
    id
  }
}
    `;