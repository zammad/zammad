import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseCategoryPreInfoFragmentDoc = gql`
    fragment knowledgeBaseCategoryPreInfo on KnowledgeBaseCategory {
  directAnswerCount(locale: $locale)
  directSubcategoryCount(locale: $locale)
  breadcrumb {
    id
    translation(locale: $locale) {
      id
      title
    }
    categoryIcon
    iconSet
    visibility(locale: $locale)
  }
}
    `;