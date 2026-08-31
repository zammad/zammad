import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const KnowledgeBaseCategoryPolicyFragmentDoc = gql`
    fragment knowledgeBaseCategoryPolicy on KnowledgeBaseCategory {
  policy {
    update
    destroy
    createSubcategory
    createAnswer
    updateAnswer
  }
}
    `;