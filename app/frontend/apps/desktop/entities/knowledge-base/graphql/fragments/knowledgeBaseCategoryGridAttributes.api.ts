import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseCategoryGridAttributesFragmentDoc = gql`
    fragment knowledgeBaseCategoryGridAttributes on KnowledgeBaseCategory {
  id
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
  categoryIcon
  visibility(locale: $locale)
  answerCount(locale: $locale)
  subcategoryCount(locale: $locale)
  position
  isDeletable
  ...knowledgeBaseCategoryPolicy
  ...knowledgeBaseCategoryPreInfo
}
    `;