import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseCategoryPreInfoFragmentDoc = gql`
    fragment knowledgeBaseCategoryPreInfo on KnowledgeBaseCategory {
  directAnswerCount
  directSubcategoryCount
  breadcrumb {
    id
    title
    categoryIcon
    visibility
  }
}
    `;