import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseCategoryBreadcrumbFragmentDoc = gql`
    fragment knowledgeBaseCategoryBreadcrumb on KnowledgeBaseCategory {
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